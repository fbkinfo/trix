#= require trix/controllers/controller
#= require trix/controllers/input_controller
#= require trix/controllers/composition_controller
#= require trix/controllers/toolbar_controller
#= require trix/models/composition
#= require trix/models/editor
#= require trix/models/attachment_manager
#= require trix/models/selection_manager

{rangeIsCollapsed, rangesAreEqual, objectsAreEqual} = Trix

class Trix.EditorController extends Trix.Controller
  constructor: ({@editorElement, document, html}) ->
    @selectionManager = new Trix.SelectionManager @editorElement
    @selectionManager.delegate = this

    @composition = new Trix.Composition
    @composition.delegate = this

    @attachmentManager = new Trix.AttachmentManager @composition.getAttachments()
    @attachmentManager.delegate = this

    @inputController = new Trix.InputController @editorElement
    @inputController.delegate = this
    @inputController.responder = @composition

    @compositionController = new Trix.CompositionController @editorElement, @composition
    @compositionController.delegate = this

    @toolbarController = new Trix.ToolbarController @editorElement.toolbarElement
    @toolbarController.delegate = this

    @editor = new Trix.Editor @composition, @selectionManager, @editorElement
    if document?
      @editor.loadDocument(document)
    else
      @editor.loadHTML(html)

  registerSelectionManager: ->
    Trix.selectionChangeObserver.registerSelectionManager(@selectionManager)

  unregisterSelectionManager: ->
    Trix.selectionChangeObserver.unregisterSelectionManager(@selectionManager)

  # Composition delegate

  compositionDidChangeDocument: (document) ->
    @editorElement.notify("document-change")
    @render() unless @handlingInput

  compositionDidChangeCurrentAttributes: (@currentAttributes) ->
    @toolbarController.updateAttributes(@currentAttributes)
    @updateCurrentActions()
    @editorElement.notify("attributes-change", attributes: @currentAttributes)

  compositionDidPerformInsertionAtRange: (range) ->
    @pastedRange = range if @pasting

  compositionShouldAcceptFile: (file) ->
    @editorElement.notify("file-accept", {file})

  compositionDidAddAttachment: (attachment) ->
    managedAttachment = @attachmentManager.manageAttachment(attachment)
    @editorElement.notify("attachment-add", attachment: managedAttachment)

  compositionDidEditAttachment: (attachment) ->
    @compositionController.rerenderViewForObject(attachment)
    managedAttachment = @attachmentManager.manageAttachment(attachment)
    @editorElement.notify("attachment-edit", attachment: managedAttachment)
    @editorElement.notify("change")

  compositionDidRemoveAttachment: (attachment) ->
    managedAttachment = @attachmentManager.unmanageAttachment(attachment)
    @editorElement.notify("attachment-remove", attachment: managedAttachment)

  compositionDidStartEditingAttachment: (attachment) ->
    document = @composition.document
    attachmentRange = document.getRangeOfAttachment(attachment)
    @attachmentLocationRange = document.locationRangeFromRange(attachmentRange)
    @compositionController.installAttachmentEditorForAttachment(attachment)
    @selectionManager.setLocationRange(@attachmentLocationRange)

  compositionDidStopEditingAttachment: (attachment) ->
    @compositionController.uninstallAttachmentEditor()
    @attachmentLocationRange = null

  compositionDidRequestChangingSelectionToLocationRange: (locationRange) ->
    return if @loadingSnapshot and not @isFocused()
    @requestedLocationRange = locationRange
    @documentWhenLocationRangeRequested = @composition.document
    @render() unless @handlingInput

  compositionWillLoadSnapshot: ->
    @loadingSnapshot = true

  compositionDidLoadSnapshot: ->
    @compositionController.refreshViewCache()
    @render()
    @loadingSnapshot = false

  getSelectionManager: ->
    @selectionManager

  @proxyMethod "getSelectionManager().setLocationRange"
  @proxyMethod "getSelectionManager().getLocationRange"

  # Attachment manager delegate

  attachmentManagerDidRequestRemovalOfAttachment: (attachment) ->
    @removeAttachment(attachment)

  # Document controller delegate

  compositionControllerWillSyncDocumentView: ->
    @inputController.editorWillSyncDocumentView()
    @selectionManager.lock()
    @selectionManager.clearSelection()

  compositionControllerDidSyncDocumentView: ->
    @inputController.editorDidSyncDocumentView()
    @selectionManager.unlock()
    @updateCurrentActions()
    @editorElement.notify("sync")

  compositionControllerDidRender: ->
    if @requestedLocationRange?
      if @documentWhenLocationRangeRequested.isEqualTo(@composition.document)
        @selectionManager.setLocationRange(@requestedLocationRange)

      @composition.updateCurrentAttributes()
      @requestedLocationRange = null
      @documentWhenLocationRangeRequested = null
    @editorElement.notify("render")

  compositionControllerDidFocus: ->
    @toolbarController.hideDialog()
    @editorElement.notify("focus")

  compositionControllerDidBlur: ->
    @editorElement.notify("blur")

  compositionControllerDidSelectAttachment: (attachment) ->
    @composition.editAttachment(attachment)

  compositionControllerDidRequestDeselectingAttachment: (attachment) ->
    if @attachmentLocationRange
      @selectionManager.setLocationRange(@attachmentLocationRange[1])

  compositionControllerWillUpdateAttachment: (attachment) ->
    @editor.recordUndoEntry("Edit Attachment", context: attachment.id, consolidatable: true)

  compositionControllerDidRequestRemovalOfAttachment: (attachment) ->
    @removeAttachment(attachment)

  # Input controller delegate

  inputControllerWillHandleInput: ->
    @handlingInput = true
    @requestedRender = false

  inputControllerDidRequestRender: ->
    @requestedRender = true

  inputControllerDidHandleInput: ->
    @handlingInput = false
    if @requestedRender
      @requestedRender = false
      @render()

  inputControllerWillPerformTyping: ->
    @recordTypingUndoEntry()

  inputControllerWillCutText: ->
    @editor.recordUndoEntry("Cut")

  inputControllerWillPasteText: (pasteData) ->
    @editor.recordUndoEntry("Paste")
    @pasting = true

  inputControllerDidPaste: (pasteData) ->
    range = @pastedRange
    @pastedRange = null
    @pasting = null

    @editorElement.notify("paste", {pasteData, range})
    @render()

  inputControllerWillMoveText: ->
    @editor.recordUndoEntry("Move")

  inputControllerWillAttachFiles: ->
    @editor.recordUndoEntry("Drop Files")

  inputControllerDidReceiveKeyboardCommand: (keys) ->
    @toolbarController.applyKeyboardCommand(keys)

  inputControllerDidStartDrag: ->
    @locationRangeBeforeDrag = @selectionManager.getLocationRange()

  inputControllerDidReceiveDragOverPoint: (point) ->
    @selectionManager.setLocationRangeFromPointRange(point)

  inputControllerDidCancelDrag: ->
    @selectionManager.setLocationRange(@locationRangeBeforeDrag)
    @locationRangeBeforeDrag = null

  # Selection manager delegate

  locationRangeDidChange: (locationRange) ->
    @composition.updateCurrentAttributes()
    @updateCurrentActions()
    if @attachmentLocationRange and not rangesAreEqual(@attachmentLocationRange, locationRange)
      @composition.stopEditingAttachment()
    @editorElement.notify("selection-change")

  # Toolbar controller delegate

  toolbarDidClickButton: ->
    @setLocationRange(index: 0, offset: 0) unless @getLocationRange()

  toolbarDidInvokeAction: (actionName) ->
    @invokeAction(actionName)

  toolbarDidToggleAttribute: (attributeName) ->
    @recordFormattingUndoEntry()
    @composition.toggleCurrentAttribute(attributeName)
    @render()
    @editorElement.focus()

  toolbarDidUpdateAttribute: (attributeName, value) ->
    @recordFormattingUndoEntry()
    @composition.setCurrentAttribute(attributeName, value)
    @render()
    @editorElement.focus()

  toolbarDidRemoveAttribute: (attributeName) ->
    @recordFormattingUndoEntry()
    @composition.removeCurrentAttribute(attributeName)
    @render()
    @editorElement.focus()

  toolbarWillShowDialog: (dialogElement) ->
    @composition.expandSelectionForEditing()
    @freezeSelection()

  toolbarDidShowDialog: (dialogName) ->
    @editorElement.notify("toolbar-dialog-show", {dialogName})

  toolbarDidHideDialog: (dialogName) ->
    @editorElement.focus()
    @thawSelection()
    @editorElement.notify("toolbar-dialog-hide", {dialogName})

  # Selection

  freezeSelection: ->
    unless @selectionFrozen
      @selectionManager.lock()
      @composition.freezeSelection()
      @selectionFrozen = true
      @render()

  thawSelection: ->
    if @selectionFrozen
      @composition.thawSelection()
      @selectionManager.unlock()
      @selectionFrozen = false
      @render()

  # Actions

  actions:
    undo:
      test: -> @editor.canUndo()
      perform: -> @editor.undo()
    redo:
      test: -> @editor.canRedo()
      perform: -> @editor.redo()
    link:
      test: -> @editor.canActivateAttribute("href")
    hint:
      test: -> @editor.canActivateAttribute("title")
    increaseBlockLevel:
      test: -> @editor.canIncreaseIndentationLevel()
      perform: -> @editor.increaseIndentationLevel() and @render()
    decreaseBlockLevel:
      test: -> @editor.canDecreaseIndentationLevel()
      perform: -> @editor.decreaseIndentationLevel() and @render()

  canInvokeAction: (actionName) ->
    if @actionIsExternal(actionName)
      true
    else
      !! @actions[actionName]?.test?.call(this)

  invokeAction: (actionName) ->
    if @actionIsExternal(actionName)
      @editorElement.notify("action-invoke", {actionName})
    else
      @actions[actionName]?.perform?.call(this)

  actionIsExternal: (actionName) ->
    /^x-./.test(actionName)

  getCurrentActions: ->
    result = {}
    for actionName of @actions
      result[actionName] = @canInvokeAction(actionName)
    result

  updateCurrentActions: ->
    currentActions = @getCurrentActions()
    unless objectsAreEqual(currentActions, @currentActions)
      @currentActions = currentActions
      @toolbarController.updateActions(@currentActions)
      @editorElement.notify("actions-change", actions: @currentActions)

  # Private

  reparse: ->
    @composition.replaceHTML(@editorElement.innerHTML)

  render: ->
    @compositionController.render()

  removeAttachment: (attachment) ->
    @editor.recordUndoEntry("Delete Attachment")
    @composition.removeAttachment(attachment)
    @render()

  recordFormattingUndoEntry: ->
    locationRange = @selectionManager.getLocationRange()
    unless rangeIsCollapsed(locationRange)
      @editor.recordUndoEntry("Formatting", context: @getUndoContext(), consolidatable: true)

  recordTypingUndoEntry: ->
    @editor.recordUndoEntry("Typing", context: @getUndoContext(@currentAttributes), consolidatable: true)

  getUndoContext: (context...) ->
    [@getLocationContext(), @getTimeContext(), context...]

  getLocationContext: ->
    locationRange = @selectionManager.getLocationRange()
    if rangeIsCollapsed(locationRange)
      locationRange[0].index
    else
      locationRange

  getTimeContext: ->
    if Trix.config.undoInterval > 0
      Math.floor(new Date().getTime() / Trix.config.undoInterval)
    else
      0

  isFocused: ->
    @editorElement is @editorElement.ownerDocument?.activeElement

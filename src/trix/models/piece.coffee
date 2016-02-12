class Trix.Piece extends Trix.Object
  @types: {}

  @registerType: (type, constructor) ->
    constructor.type = type
    @types[type] = constructor

  @fromJSON: (pieceJSON) ->
    if constructor = @types[pieceJSON.type]
      constructor.fromJSON(pieceJSON)

  constructor: (value, attributes = {}) ->
    super
    @attributes = Trix.Hash.box(attributes)

  copyWithAttributes: (attributes) ->
    new @constructor @getValue(), attributes

  copyWithAdditionalAttributes: (attributes) ->
    @copyWithAttributes(@attributes.merge(attributes))

  copyWithoutAttribute: (attribute) ->
    @copyWithAttributes(@attributes.remove(attribute))

  copy: ->
    @copyWithAttributes(@attributes)

  getAttribute: (attribute) ->
    @attributes.get(attribute)

  getAttributesHash: ->
    @attributes

  getAttributes: ->
    @attributes.toObject()

  getCommonAttributes: ->
    return {} unless piece = pieceList.getPieceAtIndex(0)
    attributes = piece.attributes
    keys = attributes.getKeys()

    pieceList.eachPiece (piece) ->
      keys = attributes.getKeysCommonToHash(piece.attributes)
      attributes = attributes.slice(keys)

    attributes.toObject()

  hasAttribute: (attribute) ->
    @attributes.has(attribute)

  hasSameStringValueAsPiece: (piece) ->
    piece? and @toString() is piece.toString()

  hasSameAttributesAsPiece: (piece) ->
    piece? and (@attributes is piece.attributes or @attributes.isEqualTo(piece.attributes))

  isBlockBreak: ->
    false

  isEqualTo: (piece) ->
    super or (
      @hasSameConstructorAs(piece) and
      @hasSameStringValueAsPiece(piece) and
      @hasSameAttributesAsPiece(piece)
    )

  isEmpty: ->
    @length is 0

  isSerializable: ->
    true

  toJSON: ->
    type: @constructor.type
    attributes: @getAttributes()

  contentsForInspection: ->
    type: @constructor.type
    attributes: @attributes.inspect()

  # Grouping

  canBeGrouped: ->
    @hasAttribute("href") or @hasAttribute("title")

  canBeGroupedWith: (piece) ->
    @getAttribute("href") is piece.getAttribute("href") or @getAttribute("title") is piece.getAttribute("title")

  # Splittable

  getLength: ->
    @length

  canBeConsolidatedWith: (piece) ->
    false

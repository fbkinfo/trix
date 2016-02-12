{makeFragment} = Trix
{lang} = Trix.config

Trix.config.toolbar =
  content: makeFragment """
    <div class="button_groups">
      <span class="button_group text_tools">
        <button type="button" class="bold" data-attribute="bold" data-key="b" title="#{lang.bold} (cmd+b)">#{lang.bold}</button>
        <button type="button" class="italic" data-attribute="italic" data-key="i" title="#{lang.italic} (cmd+i)">#{lang.italic}</button>
        <button type="button" class="strike" data-attribute="strike" title="#{lang.strike}">#{lang.strike}</button>
        <button type="button" class="link" data-attribute="href" data-action="link" data-key="k" title="#{lang.link} (cmd+k)">#{lang.link}</button>
        <button type="button" class="hint" data-attribute="title" data-action="hint" data-key="h" title="#{lang.hint} (cmd+h)">#{lang.hint}</button>
      </span>

      <span class="button_group block_tools">
        <button type="button" class="quote" data-attribute="quote" title="#{lang.quote}">#{lang.quote}</button>
        <button type="button" class="code" data-attribute="code" title="#{lang.code}">#{lang.code}</button>
        <button type="button" class="list bullets" data-attribute="bullet" title="#{lang.bullets}">#{lang.bullets}</button>
        <button type="button" class="list numbers" data-attribute="number" title="#{lang.numbers}">#{lang.numbers}</button>
        <button type="button" class="block-level decrease" data-action="decreaseBlockLevel" title="#{lang.outdent}">#{lang.outdent}</button>
        <button type="button" class="block-level increase" data-action="increaseBlockLevel" title="#{lang.indent}">#{lang.indent}</button>
      </span>

      <span class="button_group history_tools">
        <button type="button" class="undo" data-action="undo" data-key="z" title="#{lang.undo} (cmd+z)">#{lang.undo}</button>
        <button type="button" class="redo" data-action="redo" data-key="shift+z" title="#{lang.redo} (cmd+shift+z)">#{lang.redo}</button>
      </span>
    </div>

    <div class="dialogs">
      <div class="dialog link_dialog" data-attribute="href" data-dialog="href">
        <div class="link_url_fields">
          <input type="url" required name="href" placeholder="#{lang.urlPlaceholder}">
          <div class="button_group">
            <input type="button" value="#{lang.link}" data-method="setAttribute">
            <input type="button" value="#{lang.unlink}" data-method="removeAttribute">
          </div>
        </div>
      </div>
      <div class="dialog hint_dialog" data-attribute="title" data-dialog="title">
        <div class="hint_title_fields">
          <input type="text" required name="title">
          <div class="button_group">
            <input type="button" value="#{lang.hint}" data-method="setAttribute">
            <input type="button" value="#{lang.unhint}" data-method="removeAttribute">
          </div>
        </div>
      </div>
    </div>
  """

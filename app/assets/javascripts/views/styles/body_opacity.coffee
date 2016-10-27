using 'Styles'
class Styles.BodyOpacity extends View
  REGEXP = /.*GENERATED: body_opacity[\s\S]*?rgba\(([\d.]+), ([\d.]+), ([\d.]+), (\d+)[\s\S]*?GENERATED: \/body_opacity.*/

  ZERO_OPACITY = 255
  DEFAULT_OPACITIES = [ZERO_OPACITY, ZERO_OPACITY, ZERO_OPACITY, 1]

  DEBOUNCE_INTERVAL = 100

  initialize: (@$css) ->
    @slider = @$('.range-slider')[0]
    @css_template = @$root.data 'css_template'
    @opacities = @_extract_opacities()

    @_init_slider()

  update: ->

  _extract_opacities: ->
    matches = @$css.val().match(REGEXP)

    if matches
      matches[1..4].map (v) -> parseFloat v
    else
      DEFAULT_OPACITIES

  _init_slider: ->
    noUiSlider.create @slider,
      range:
        min: 0
        max: 12
      start: parseFloat(ZERO_OPACITY - @opacities.first()) || 0

    @slider.noUiSlider.on 'update', @_slider_update.debounce(DEBOUNCE_INTERVAL)

  _slider_update: (value) =>
    unless @first_update
      @first_update = true
      return

    console.log 'slider_update'
    opacity = ZERO_OPACITY - parseFloat(value)
    @opacities = [opacity, opacity, opacity, @opacities[3]]
    @_update_css()

  _update_css: ->
    css = @$css.val()

    if css.match(REGEXP)
      @$css.val css.replace(REGEXP, @_compile())
    else
      @$css.val @_compile() + "\n\n" + css

    @trigger 'component:update'

  _compile: ->
    @css_template
      .replace(/%d/, @opacities[0])
      .replace(/%d/, @opacities[1])
      .replace(/%d/, @opacities[2])
      .replace(/%d/, @opacities[3])

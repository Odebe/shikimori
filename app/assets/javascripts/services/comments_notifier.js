import delay from 'delay';

import JST from 'helpers/jst';

const COMMENT_SELECTOR = 'div.b-appear_marker.active';
const FAYE_LOADER_SELECTOR = '.faye-loader';

// уведомлялка о новых комментариях
// назначение класса - смотреть на странице новые комментаы и отображать информацию об этом
export default class CommentsNotifier {
  $container = null
  currentCounter = 0

  maxTop = 31
  blockTop = 0

  constructor() {
    // при загрузке новой страницы вставляем в DOM счётчик
    $(document).on('page:load', () => this.$container = null);
    // при прочтении комментов, декрементим счётчик
    $(document).on('appear', (e, $appeared, byClick) => this._appear(e, $appeared, byClick));
    // при добавление блока о новом комментарии/топике делаем инкремент
    $(document).on('faye:added', () => this._incrementCounter());
    // при загрузке контента аяксом, fayer-loader'ом, postloader'ом, при перезагрузке страницы
    $(document).on(
      'page:load page:restore faye:loaded ajax:success postloader:success',
      () => this._refresh()
    );

    // явное указание о скрытии
    $(document).on('disappear', () => this._decrementCounter());
    // при добавление блока о новом комментарии/топике делаем инкремент
    $(document).on('reappear', () => this._incrementCounter());

    // смещение вверх-вниз блока уведомлялки
    this.scroll = $(window).scrollTop();

    $(window).scroll(() => {
      if (!this.$container) { return; }

      this.scroll = $(window).scrollTop();

      if ((this.scroll <= this.maxTop) ||
        ((this.scroll > this.maxTop) && (this.blockTop !== 0))
      ) {
        this._move();
      }
    });

    this._refresh();
  }

  _$container() {
    if (!this.$container) {
      this.$container = $(this._render())
        .appendTo(document.body)
        .on('click', () => {
          const $firstUnread = $(`${COMMENT_SELECTOR}, ${FAYE_LOADER_SELECTOR}`).first();
          $.scrollTo($firstUnread);
        });

      this.scroll = $(window).scrollTop();
    }

    return this.$container;
  }

  _render() {
    return JST['comments/notifier']();
  }

  async _refresh() {
    await delay();
    const $commentNew = $(COMMENT_SELECTOR);
    const $fayeLoader = $(FAYE_LOADER_SELECTOR);

    let count = $commentNew.length;

    $fayeLoader.each(function () {
      count += $(this).data('ids').length;
    });

    this._update(count);
  }

  _update(count) {
    this.currentCounter = count;

    if (count > 0) {
      this._$container().show().html(this.currentCounter);
    } else if (this.$container) {
      this._$container().hide();
    }
  }

  _appear(e, $appeared, _byClick) {
    const $nodes = $appeared
      .filter(`${COMMENT_SELECTOR}, ${FAYE_LOADER_SELECTOR}`)
      .not(function () { return $(this).data('disabled'); });

    this._update(this.currentCounter - $nodes.length);
  }

  _decrementCounter() {
    this._update(this.currentCounter - 1);
  }

  _incrementCounter() {
    this._update(this.currentCounter + 1);
  }

  _move() {
    this.blockTop = [0, this.maxTop - this.scroll].max();
    this._$container().css({ top: this.blockTop });
  }
}

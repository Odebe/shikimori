class AniMangaPresenter::RelatedPresenter < BasePresenter
  prepend ActiveCacher.instance
  VISIBLE_RELATED = 7

  instance_cache :related, :similar, :all

  # связанные аниме
  def related
    all
      .map {|v| RelatedEntry.new v.anime || v.manga, v.relation }
      #.sort_by {|v| v.relation == BaseMalParser::RelatedAdaptationName ? 0 : 1 }
  end

  # похожие аниме
  def similar
    entry
      .similar
      .includes(:dst)
      .select {|v| v.dst && v.dst.name } # т.к.связанные аниме могут быть ещё не импортированы
      .map(&:dst)
  end

  # есть ли они вообще?
  def any?
    related.any?
  end

  # одно ли связанное аниме?
  def one?
    related.size == 1
  end

  # достаточно ли большое число связанных аниме?
  def many?
    related.size > VISIBLE_RELATED
  end

  def all
    entry
      .related
      .includes(:anime, :manga)
      .select { |v| (v.anime_id && v.anime && v.anime.name) || (v.manga_id && v.manga && v.manga.name) }
      .sort_by do |v|
        (v.anime_id ? v.anime.aired_on : nil) ||
          (v.manga_id ? v.manga.aired_on : nil) ||
          Date.new(9999)
      end
  end
end

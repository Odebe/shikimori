class VersionsQuery < QueryObjectBase
  def self.fetch item
    new(
      Version
        .where(item: item)
        .or(Version.where(associated: item))
        .where.not(state: :deleted)
        .includes(:user, :moderator)
        .order(created_at: :desc)
    )
  end

  def by_field field
    chain @scope.where(field_sql(field), field: field)
  end

  def authors field
    by_field(field)
      .where(field_sql(field), field: field)
      .where(state_condition(field))
      .where(state: %i[accepted auto_accepted])
      .except(:order)
      .order(created_at: :asc)
      .map(&:user)
      .uniq { |user| user.bot? ? 'bot' : user }
  end

private

  def field_sql field
    if field.to_sym == :videos
      "(item_diff->>:field) is not null or item_type = '#{Video.name}'"
    else
      '(item_diff->>:field) is not null'
    end
  end

  def state_condition field
    return unless field.to_sym == :screenshots || field.to_sym == :videos

    screenshots_sql = ApplicationRecord.sanitize(
      Versions::ScreenshotsVersion::Actions[:upload]
    )

    videos_sql = ApplicationRecord.sanitize(
      Versions::VideoVersion::Actions[:upload]
    )

    "(item_diff->>'action') in (#{screenshots_sql}, #{videos_sql})"
  end
end

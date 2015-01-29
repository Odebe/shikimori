class AnimeOnline::AnimeVideosController < AnimesController
  load_and_authorize_resource only: [:new, :create, :edit, :update]

  before_action :actualize_resource, only: [:new, :create, :edit, :update]
  before_action :authenticate_user!, only: [:viewed]
  before_action :add_breadcrumb, except: [:index]

  after_action :save_preferences, only: :index

  def index
    return redirect_to valid_host_url unless valid_host?
    raise ActionController::RoutingError.new('Not Found') if @anime.anime_videos.blank?

    @player = AnimeOnline::VideoPlayer.new @anime
    @video = @player.current_video
    page_title @player.episode_title
  end

  def new
    page_title 'Новое видео'
    raise ActionController::RoutingError.new 'Not Found' if AnimeVideo::CopyrightBanAnimeIDs.include?(@anime.id) && (!user_signed_in? || !current_user.admin?)
  end

  def edit
    page_title 'Изменение видео'
    #@video = AnimeVideo.includes(:anime).find params[:id]
  end

  def create
    #@video = AnimeVideo.new(video_params.merge(url: VideoExtractor::UrlExtractor.new(video_params[:url]).extract))
    @video.url = VideoExtractor::UrlExtractor.new(@video.url).extract
    @video.author = find_or_create_author(params[:anime_video][:author])

    if @video.save
      #AnimeVideoReport.create!(user: current_user, anime_video: @video, kind: :uploaded)

      if params[:continue] == 'true'
        flash[:notice] = "Эпизод #{@video.episode} добавлен"
        @created_video = @video
        @video = AnimeVideo.new @video.attributes.except(:id, :url)
      else
        return redirect_to play_video_online_index_url(@anime.id, @video.episode, @video.id), notice: 'Видео добавлено'
      end
    end

    render :new
  end

  #def update
    #@video = AnimeVideo.find(params[:id])
    #author = find_or_create_author(params[:anime_video][:author])
    #if video_params[:episode] != @video.episode || video_params[:kind] != @video.kind || author.id != @video.author_id
      #if @video.moderated_update video_params.merge(anime_video_author_id: author.id), current_user
        #redirect_to anime_videos_show_url(@video.anime.id, @video.episode, @video.id), notice: 'Видео изменено'
      #else
        #render :edit
      #end
    #end
  #end

  def viewed
    video = AnimeVideo.find params[:id]
    @user_rate = @anime.rates.find_by(user_id: current_user.id) ||
      @anime.rates.build(user: current_user)

    @user_rate.update! episodes: video.episode if @user_rate.episodes < video.episode
    render nothing: true
  end

  def track_view
    AnimeVideo.find(params[:id]).increment! :watch_view_count
    render nothing: true
  end

  def extract_url
    render json: { url: VideoExtractor::UrlExtractor.new(params[:url]).extract }
  end

  #def search
    #search = params[:search].to_s.strip
    #if search.blank?
      #redirect_to root_url
    #else
      #redirect_to anime_videos_url search: params[:search], page: 1
    #end
  #end

  #def new
    #anime = Anime.find params[:anime_id]
    #raise ActionController::RoutingError.new 'Not Found' if AnimeVideo::CopyrightBanAnimeIDs.include?(anime.id) && (!user_signed_in? || !current_user.admin?)
    #@video = AnimeVideo.new anime: anime, source: 'shikimori.org', kind: :fandub
  #end

  #def update
    #@video = AnimeVideo.find(params[:id])
    #author = find_or_create_author(params[:anime_video][:author])
    #if video_params[:episode] != @video.episode || video_params[:kind] != @video.kind || author.id != @video.author_id
      #if @video.moderated_update video_params.merge(anime_video_author_id: author.id), current_user
        #redirect_to anime_videos_show_url(@video.anime.id, @video.episode, @video.id), notice: 'Видео изменено'
      #else
        #render :edit
      #end
    #end
  #end

  #def destroy
    #video = AnimeVideo.find(params[:id])
    #report = AnimeVideoReport.where(user_id: current_user, anime_video_id: params[:id]).first
    #if report
      #video.destroy
    #end
    #redirect_to anime_videos_show_url(video.anime_id), notice: 'Видео удалено'
  #end

  #def help
  #end

  #def viewed
    #video = AnimeVideo.find params[:id]
    #anime = Anime.find params[:anime_id]
    #user_rate = anime.rates.find_by_user_id current_user.id
    #UserRate.update(user_rate.id, episodes: video.episode) if user_rate

    #redirect_to anime_videos_show_url video.anime_id, video.episode + 1
  #end

  #def rate
    #UserRate.create_or_find(current_user.id, params[:id], 'Anime').save
    #render nothing: true
  #end


private
  def resource_params
    params
      .require(:anime_video)
      .permit(:episode, :url, :anime_id, :source, :kind, :state)
  end

  def find_or_create_author name
    name = name.to_s.strip
    AnimeVideoAuthor.where(name: name).first ||
      AnimeVideoAuthor.create(name: name)
  end

  def resource_id
    params[:anime_id]
  end

  def resource_klass
    Anime
  end

  def save_preferences
    if @video && @video.persisted? && @video.valid?
      cookies[:preference_kind] = @video.kind
      cookies[:preference_hosting] = @video.hosting
      cookies[:preference_author_id] = @video.anime_video_author_id
    end
  end

  def valid_host?
    AnimeOnlineDomain::valid_host? @anime, request
  end

  def valid_host_url
    play_video_online_index_url @anime,
      episode: params[:episode], video_id: params[:video_id],
      domain: AnimeOnlineDomain::host(@anime), subdomain: false
  end

  def add_breadcrumb
    episode = @video.try(:episode)
    index_url = play_video_online_index_url(@anime, episode: episode)

    breadcrumb episode ? "Эпизод #{episode}" : 'Просмотр онлайн', index_url
    @back_url = index_url
  end

  def actualize_resource
    @video = @resource
    @resource = @anime
  end
end


require 'thor'
require 'json'  
require "active_support/core_ext"
require 'fileutils'

require_relative "wechat-rails"


class App < Thor                                                 
  class Helper
    def self.with(options)
      appid =  Wechat.config.appid
      secret = Wechat.config.secret
      token_file = options[:toke_file] || Wechat.config.access_token

      if (appid.nil? || secret.nil? || token_file.nil?)
      puts <<-HELP
You need create ~/.wechat.yml with wechat appid and secret. For example:

  appid: <wechat appid>
  secret: <wechat secret>
  access_toke: "/var/tmp/wechat_access_token"

HELP
      exit 1
      end
      Wechat::Api.new(appid, secret, token_file)
    end
  end

  package_name "Wechat"
  option :toke_file, :aliases=>"-t", :desc => "File to store access token"

  desc "users", "关注者列表"
  def users
    puts Helper.with(options).users
  end

  desc "user [OPEN_ID]", "查找关注者"
  def user(open_id)
    puts Helper.with(options).user(open_id)
  end

  desc "menu", "当前菜单"
  def menu
    puts Helper.with(options).menu
  end

  desc "menu_delete", "删除菜单"
  def menu_delete
    puts "Menu deleted" if Helper.with(options).menu_delete
  end

  desc "menu_create [MENU_YAML]", "创建菜单"
  def menu_create(menu_yaml)
    menu = YAML.load(File.new(menu_yaml).read)
    puts "Menu created" if Helper.with(options).menu_create(menu)
  end

  desc "media [MEDIA_ID, PATH]", "媒体下载"
  def media(media_id, path)
    tmp_file = Helper.with(options).media(media_id)
    FileUtils.mv(tmp_file.path, path)
    puts "File downloaded"
  end

  desc "media_create [MEDIA_ID, PATH]", "媒体上传"
  def media_create(type, path)
    file = File.new(path)
    puts Helper.with(options).media_create(type, file)
  end
  
  desc "custom_text [OPENID, TEXT_MESSAGE]", "发送文字客服消息"
  def custom_text openid, text_message
    puts Helper.with(options).custom_message_send Wechat::Message.to(openid).text(text_message)
  end

  desc "custom_image [OPENID, IMAGE_PATH]", "发送图片客服消息"
  def custom_image openid, image_path
    file = File.new(image_path)
    api = Helper.with(options)

    media_id = api.media_create("image", file)["media_id"]
    puts api.custom_message_send Wechat::Message.to(openid).image(media_id)
  end

  desc "custom_voice [OPENID, VOICE_PATH]", "发送语音客服消息"
  def custom_voice openid, voice_path
    file = File.new(voice_path)
    api = Helper.with(options)

    media_id = api.media_create("voice", file)["media_id"]
    puts api.custom_message_send Wechat::Message.to(openid).voice(media_id)
  end

  desc "custom_video [OPENID, VIDEO_PATH]", "发送视频客服消息"
  method_option :title, :aliases => "-h", :desc => "视频标题"
  method_option :description, :aliases => "-d", :desc => "视频描述"
  def custom_video openid, video_path
    file = File.new(video_path)
    api = Helper.with(options)

    api_opts = options.slice(:title, :description)
    media_id = api.media_create("video", file)["media_id"]
    puts api.custom_message_send Wechat::Message.to(openid).video(media_id, api_opts)
  end

  desc "custom_music [OPENID, THUMBNAIL_PATH, MUSIC_URL]", "发送音乐客服消息"
  method_option :title, :aliases => "-h", :desc => "音乐标题"
  method_option :description, :aliases => "-d", :desc => "音乐描述"
  method_option :HQ_music_url, :aliases => "-u", :desc => "高质量音乐URL链接"
  def custom_music openid, thumbnail_path, music_url
    file = File.new(thumbnail_path)
    api = Helper.with(options)

    api_opts = options.slice(:title, :description, :HQ_music_url)
    thumb_media_id = api.media_create("thumb", file)["thumb_media_id"]
    puts api.custom_message_send Wechat::Message.to(openid).music(thumb_media_id, music_url, api_opts)
  end

  desc "custom_news [OPENID, NEWS_YAML_FILE]", "发送图文客服消息"
  def custom_news openid, news_yaml
    articles = YAML.load(File.new(news_yaml).read)
    puts Helper.with(options).custom_message_send Wechat::Message.to(openid).news(articles["articles"])
  end

end
FBomb {

##
#
  command(:reload){
    help 'reload fbomb commands'
    
    call do |*args|
      FBomb::Command.table = FBomb::Command::Table.new
      FBomb::Command.load(Command.command_paths)
      speak('locked and loaded.')
    end
  }

##
#  
  command(:rhymeswith) {
    help 'show ryhming words'

    setup{ require 'cgi' }

    call do |*args|
      args.each do |arg|
        if arg.strip == 'orange'
          speak('nothing rhymes with orange dumbass')
        else
          word = CGI.escape(arg.strip)
          url = "http://www.zachblume.com/apis/rhyme.php?format=xml&word=#{ word }"
          data = `curl --silent #{ url.inspect }`
          words = data.scan(%r|<word>([^<]*)</word>|).flatten
          msg = words.join(" ")
          speak(msg)
        end
      end
    end
  }

##
#
  command(:chucknorris) {
    call do |*args|
      data = JSON.parse(`curl --silent 'http://api.icndb.com/jokes/random'`)
      msg = data['value']['joke']
      speak(msg) unless msg.strip.empty?
    end
  }

##
#
  command(:fukung) {
    call do |*args|
      tags = args.join(' ').strip.downcase
      if tags.empty?
        msg = Array(Fukung.random).sort_by{ rand }.first(3).join("\n")
      else
        msg = Fukung.tag(tags).sort_by{ rand }.first(3).join("\n")
      end
      speak(msg) unless msg.strip.empty?
    end
  }

##
#
  command(:google) {
    setup{ require "google-search" }

    call do |*args|
      type = args.first
      msg = ""
      case type
        when /image|img|i/i
          args.shift
          query = args.join(' ')
          @cache ||= []
          images = Google::Search::Image.new(:query => query, :image_size => :small)
          if images.any?
            images.each do |result|
              next if @cache.include? result.id
              @cache << result.id
              msg = "#{ result.uri }\n"
              break
            end
          else
            msg = "No results for: #{query}"
          end
        else
          query = args.join(' ')
          Google::Search::Web.new(:query => query).each do |result|
            msg << "#{ result.uri }\n"
          end
      end
      speak(msg) unless msg.empty?
    end
  }
  
##
#
  command(:fail){
    setup{ require "nokogiri"}

    call do |*args|
      msg = ""
      query = CGI.escape(args.join(' ').strip)
      url = "http://failblog.org/?s=#{query}"
      data = `curl --silent #{ url.inspect }`
      doc = Nokogiri::HTML(data)
      images = doc.search('div.entry img').collect{|i| i.get_attribute('src')}
      @cache ||= []
      if images.any?
        images.each do |result|
          next if @cache.include? result
          @cache << result
          msg = "#{ result }\n"
          break
        end
      else
        msg = "No results for: #{query}"
      end
      speak(msg) unless msg.empty?
    end
  }
  
##
#
  command(:gist) {
    call do |*args|
      url = args.join(' ').strip

      id = url.scan(/\d+/).first
      gist_url = "https://gist.github.com/#{ id }"
      speak(gist_url)

      gist_html = `curl --silent #{ gist_url.inspect }`
      re = %r| <a\s+href\s*=\s*" (/raw[^">]+) "\s*>\s*raw\s*</a> |iox
      match, raw_path = re.match(gist_html).to_a

      if match
        raw_url = "https://gist.github.com#{ raw_path }"
        raw_html = `curl --silent --location #{ raw_url.inspect }`
        paste(raw_html)
      end
    end
  }

##
#
  command(:xkcd) {
    call do |*args|
      id = args.shift || rand(1000)
      url = "http://xkcd.com/#{ id }/"
      html = `curl --silent #{ url.inspect }`
      doc = Nokogiri::HTML(html)
      links = []
      doc.xpath('//h3').each do |node|
        text = node.text
        case text
          when %r'Permanent link to this comic:', %r'hotlinking/embedding'
            link = text.split(':').last
            link = "http:#{ link }" unless link['://']
            links << link
        end
      end
      links.each do |link|
        speak(link)
      end
    end
  }

##
#
  command(:goodfuckingdesignadvice) {
    call do |*args|
      url = "http://goodfuckingdesignadvice.com/index.php"
      html = `curl --location --silent #{ url.inspect }`
      doc = Nokogiri::HTML(html)
      msg = nil
      doc.xpath('//div').each do |node|
        if node['class'] =~ /advice/
          text = node.text
          msg = text
        end
      end
      speak(msg) if msg
    end
  }

##
#
  command(:designquote) {
    call do |*args|
      url = "http://quotesondesign.com"
      cmd = "curl --location --silent #{ url.inspect }"
      html = `#{ cmd  }`
      doc = Nokogiri::HTML(html)
      msg = nil
      doc.xpath('//div').each do |node|
        if node['id'] =~ /post-/
          text = node.text
          break(msg = text)
        end
      end
      if msg
        msg = msg.gsub(%r'\[\s+permalink\s+\]', '').gsub(%r'\[\s+Tweet\s+This\s+\]', '').strip
        msg = Unidecoder.decode(msg)
        speak(msg)
      end
    end
  }

##
#
  command(:quote) {
    call do |*args|
      url = "http://iheartquotes.com/api/v1/random?format=html&max_lines=4&max_characters=420"
      html = `curl --location --silent #{ url.inspect }`
      doc = Nokogiri::HTML(html)
      msg = nil
      #<a target="_parent" href='http://iheartquotes.com/fortune/show/victory_uber_allies_'>Victory uber allies!</a>
      doc.xpath('//div[@class="rbcontent"]/a').each do |node|
        text = node.text
        msg = text
      end
      speak(msg) if msg
    end
  }

##
#
  command(:people){
    call do |*args|
      msgs = []
      room.users.each do |user|
        name = user['name']
        email_address = user['email_address']
        avatar_url = user['avatar_url']
        speak(avatar_url)
        speak("#{ name } // #{ email_address }")
      end
    end
  }

##
#
  command(:peeps){
    call do |*args|
      msgs = []
      room.users.each do |user|
        name = user['name']
        email_address = user['email_address']
        msgs.push("#{ name }")
      end
      speak(msgs.join(', '))
    end
  }

##
#
  command(:rawk){
    call do |*args|
      urls = %w(
        http://s3.amazonaws.com/drawohara.com.images/angus1.gif
        http://img.maniadb.com/images/artist/117/117027.jpg
        http://images.starpulse.com/Photos/pv/Van%20Halen-7.JPG
      )
      speak(urls[rand(urls.size)])
    end
  }

##
#
  command(:pixtress){
    call do |*args|
      url = "http://pixtress.tumblr.com/random"
      error = nil

      4.times do
        begin
          agent = Mechanize.new
          agent.open_timeout = 240
          agent.read_timeout = 240

          page = agent.get(url)

          page.search('//div[@class="ThePhoto"]/a').each do |node|
            node.search('//img').each do |img|
              src = img['src']
              alt = img['alt']
              url = src

              image = agent.get(src)

              Util.tmpdir do
                open(image.filename, 'w'){|fd| fd.write(image.body)}

                url = File.join(room.url, "uploads.xml")
                cmd = "curl -Fupload=@#{ image.filename.inspect } #{ url.inspect }"
                system(cmd)
                speak(alt)
              end

              break
            end
          end

          break
        rescue Object => error
          :retry
        end
      end

      raise error if error
    end
  }

##
#
  command(:shaka){
    call do |*args|
      speak('http://s3.amazonaws.com/drawohara.com.images/shaka.jpg')
    end
  }

##
#
  command(:unicorn){
    setup{ require "google-search" }

    urls = [
      'http://ficdn.fashionindie.com/wp-content/uploads/2010/04/exterface_unicorn_03.jpg', 
      'http://fc04.deviantart.net/fs51/f/2009/281/a/7/White_Unicorn_My_Little_Pony_by_Barkingmadd.jpg',
      'http://th54.photobucket.com/albums/g119/jasonjmore/th_UnicornPeeingRainbow.jpg',
      'http://th242.photobucket.com/albums/ff99/1010496/th_unicornpr0n.gif'
    ]

    call do |*args|
      if args.first == 'bomb'
        n = Integer(args[1] || [3, rand(10)].max)
        images = Google::Search::Image.new(:query => 'unicorn', :image_size => :medium)
        images = images.map{|result| result.uri}.uniq.sort_by{ rand }
        n.times{ speak(msg = images.pop) }
      else
        speak(urls.sample)
      end
    end
  }

}


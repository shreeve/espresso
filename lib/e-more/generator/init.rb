class EspressoGenerator
  include EspressoUtils

  INDENT = (" " * 2).freeze
  attr_reader :boot_file
  attr_accessor :logger

  def initialize dst_root, logger = nil
    src_root  = File.expand_path('../../../../app', __FILE__) + '/'
    @src_path = %w[base gemfiles database].inject({}) do |map,path|
      map.merge path.to_sym => (src_root + path + '/').freeze
    end.freeze

    @dst_root  = (dst_root  + '/').gsub(/\/+/, '/').freeze
    @boot_file = (@dst_root + 'base/boot.rb').freeze
    @logger    = logger || logger == false ? logger : Logger.new(STDOUT)
  end

  def dst_path *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    root = @dst_root + opts[:append].to_s + '/'
    paths = {
      :root => root,
      :base => File.join(root, 'base/'),
      :config => File.join(root, 'config/')
    }
    [:controllers, :models, :views].each do |u|
      paths[u] = File.join(paths[:base], u.to_s, '')
    end
    unit = paths[args.first] ? args.shift : nil
    unit ? File.join(paths[unit], *args) : paths
  end

  def in_app_folder?
    File.directory?(dst_path[:controllers]) ||
      fail("Seems current folder is not a generated Espresso application")
  end

  def parse_input *input
    args, setups, string_setups = [], {}, []
    input.flatten.each do |a|
      case
      when a =~ /\Ao(\w+)?:/i, a =~ /\Am:/i
        orm = extract_setup(a)
        if valid_orm = valid_orm?(orm)
          setups[:orm] = valid_orm
          string_setups << a
        else
          o 'WARN: invalid ORM provided - "%s"' % orm
          o 'Supported ORMs: ActiveRecord, DataMapper, Sequel'
          fail
        end
      when a =~ /\Ae(\w+)?:\w+/i
        engine = extract_setup(a).to_s.to_sym
        if valid_engine?(engine)
          setups[:engine] = engine
          string_setups << a
        else
          o 'WARN: invalid engine provided - "%s"' % engine
          o 'Supported engines(Case Sensitive): %s' % VIEW__ENGINE_BY_SYM.keys.join(', ')
          fail
        end
      when a =~ /\Af(\w+)?:/
        if format = extract_setup(a)
          setups[:format] = format
          string_setups << a
        end
      when a =~ /\Ar(\w+)?:/
        if route = extract_setup(a)
          setups[:route] = route
          string_setups << a
        end
      else
        args << a
      end
    end
    [args.freeze, setups.freeze, string_setups.join(' ').freeze]
  end

end

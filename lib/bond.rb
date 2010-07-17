require 'bond/m'
require 'bond/version'
require 'bond/readline'
require 'bond/rawline'
require 'bond/agent'
require 'bond/search'
require 'bond/input'
require 'bond/rc'
require 'bond/mission'
require 'bond/missions/default_mission'
require 'bond/missions/method_mission'
require 'bond/missions/object_mission'
require 'bond/missions/anywhere_mission'
require 'bond/missions/operator_method_mission'
require 'bond/yard'

module Bond
  extend self

  # Defines a completion rule (Mission). A valid Mission consists of a condition and an action. A
  # condition is specified with one of the following options: :on, :object, :anywhere or :method(s). Each
  # of these options creates a different Mission class. An action is either this method's block or :action.
  # An action takes what the user has typed (Input) and returns an array of possible completions. Bond
  # searches these completions and returns matching completions. This searching behavior can be configured
  # or turned off per mission with :search. If turned off, the action must also handle searching.
  #
  # ==== Examples:
  #  Bond.complete(:method=>'shoot') {|input| %w{to kill} }
  #  Bond.complete(:on=>/^((([a-z][^:.\(]*)+):)+/, :search=>false) {|input| Object.constants.grep(/#{input.matched[1]}/) }
  #  Bond.complete(:object=>ActiveRecord::Base, :search=>:underscore, :place=>:last)
  #  Bond.complete(:method=>'you', :search=>proc {|input, list| list.grep(/#{input}/i)} ) {|input| %w{Only Live Twice} }
  #  Bond.complete(:method=>'system', :action=>:shell_commands)
  #
  # @param [Hash] options
  # @option options [Regexp] :on Matches the full line of input to create a Mission object.
  # @option options [String] :method See {MethodMission}
  # @option options [Array<String>] :methods See {MethodMission}
  # @option options [String] :class See {MethodMission}
  # @option options [Symbol,false] :search Determines how completions are searched. Defaults to
  #   Search.default_search. If false, search is turned off and assumed to be done in the action.
  #   Possible symbols are :anywhere, :ignore_case, :underscore, :normal, :files and :modules.
  #   See {Search} for more info.
  # @option options [String] :object See {ObjectMission}
  # @option options [String,Symbol] :action Rc method name that takes an Input and returns possible completions.
  #   See {MethodMission} for specific behavior with :method(s).
  # @option options [Integer,:last] :place Indicates where a mission is inserted amongst existing
  #   missions. If the symbol :last, places the mission at the end regardless of missions defined
  #   after it. Multiple declarations of :last are kept last in the order they are defined.
  # @option options [Symbol,String] :name Unique id for a mission which can be passed by
  #   Bond.recomplete to identify and replace the mission.
  # @option options [String] :anywhere See {AnywhereMission}
  # @option options [String] :prefix See {AnywhereMission}
  def complete(options={}, &block); M.complete(options, &block); end

  # Redefines an existing completion mission to have a different action. The condition can only be varied if :name is
  # used to identify and replace a mission. Takes same options as {#complete}.
  # ==== Example:
  #   Bond.recomplete(:on=>/man/, :name=>:count) { %w{4 5 6}}
  def recomplete(options={}, &block); M.recomplete(options, &block); end

  # Reports what completion mission matches for a given input. Helpful for debugging missions.
  # ==== Example:
  #   >> Bond.spy "shoot oct"
  #   Matches completion mission for method matching "shoot".
  #   Possible completions: ["octopussy"]
  def spy(*args); M.spy(*args); end

  # @return [Hash] Global config
  def config; M.config; end

  # Starts Bond with a default set of completions that replace and improve irb's completion. Loads completions
  # in this order: lib/bond/completion.rb, lib/bond/completions/*.rb and the following optional completions:
  # completions from :gems, completions from :yard_gems, ~/.bondrc, ~/.bond/completions/*.rb and from block. See
  # {Rc} for the DSL to use in completion files and in the block.
  #
  # ==== Examples:
  #   Bond.start :gems=>%w{hirb}
  #   Bond.start(:default_search=>:ignore_case) do
  #     complete(:method=>"Object#respond_to?") {|e| e.object.methods }
  #   end
  #
  # @param [Hash] options Sets global keys in {#config}, some which specify what completions to load.
  # @option options [Array<String>] :gems Gems which have their completions loaded from
  #   @gem_source/lib/bond/completions/*.rb.
  # @option options [Array<String>] :yard_gems Gems using yard documentation to generate completions. See {Yard}.
  # @option options [Module] :readline_plugin (Readline) Specifies a Bond plugin to interface with a Readline-like
  #   library. Available plugins are Readline and Rawline.
  # @option options [Proc] :default_mission (DefaultMission) Sets default completion to use when no missions match.
  #  See {Agent#default_mission}.
  # @option options [Symbol] :default_search (:underscore) Name of a *_search method in Rc to use as the default
  #   search in completions. See {#complete}'s :search option for valid values.
  # @option options [Binding] :eval_binding (TOPLEVEL_BINDING) Binding to use when evaluating objects in
  #   ObjectMission and MethodMission. When in irb, defaults to irb's current binding.
  # @option options [Boolean] :debug (false) Shows the stacktrace when autocompletion fails and raises exceptions
  #   in Rc.eval.
  # @option options [Boolean] :eval_debug (false) Raises eval errors occuring when finding a matching completion.
  #   Useful to debug an incorrect completion.
  def start(options={}, &block); M.start(options, &block); end

  # Loads completions for gems that ship with them under lib/bond/completions/, relative to the gem's base directory.
  def load_gems(*gems); M.load_gems(*gems); end

  # Generates and loads completions for yardoc documented gems.
  # @param *gems Gem(s) with optional options hash at the end
  # @option *gems :verbose[Boolean] (false) Displays additional information when building yardoc.
  # @option *gems :reload[Boolean] (false) Rebuilds yard databases. Use when gems have changed versions.
  def load_yard_gems(*gems); Yard.load_yard_gems(*gems); end

  # An Agent who saves all Bond.complete missions and executes the correct one when a completion is called.
  def agent; M.agent; end

  # Lists all methods that have argument completion.
  def list_methods; MethodMission.all_methods; end
end
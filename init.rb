# Redmine gompertan plugin
require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Gompertan plugin for RedMine'

Redmine::Plugin.register :gompertan_plugin do
  name :'Gompertan plugin'
  author 'chocoapricot'
  description 'This is a gompertan plugin for Redmine'
  version 'Foxtrot-100914'
  settings :default => {'show_days' => '30', 'show_cwday1' => '1', 'show_cwday2' => '1', 'show_cwday3' => '1', 'show_cwday4' => '1', 'show_cwday5' => '1', 'show_cwday6' => '1', 'show_cwday7' => '1'}, :partial => 'settings/gompertan_settings'

  # This plugin adds a project module
  # It can be enabled/disabled at project level (Project settings -> Modules)
  project_module :gompertan_module do
    # A public action
    permission :gompertan_view, {:gompertan => [:view]}, :public => true
    permission :gompertan_graph, {:gompertan => [:graph]}, :public => true
    # This permission has to be explicitly given
    # It will be listed on the permissions screen
    # permission :example_say_goodbye, {:example => [:say_goodbye]}
  end

  # A new item is added to the project menu
  menu :project_menu, :gompertan_plugin, { :controller => 'gompertan', :action => 'view' }, :caption => :label_plugin_gompertan
end

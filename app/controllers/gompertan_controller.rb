# Gompertan plugin controller
require 'SVG/Graph/Line'

class GompertanController < ApplicationController
  unloadable
  
  layout 'base'  
  before_filter :find_project, :find_tracker, :authorize

  def view
  end

  def graph
    data = graph_gompeltz
    if data
      headers["Content-Type"] = "image/svg+xml"
      send_data(data, :type => "image/svg+xml", :disposition => "inline")
    else
      render_404
    end
  end

private
  def find_project   
    @project=Project.find(params[:id])
  end

  def find_tracker
    unless params[:tracker_id].blank?
      @tracker = Tracker.find(params[:tracker_id])
    end
  end

  def graph_gompeltz
    days = Setting.plugin_gompertan_plugin['show_days'].to_i
    date_from = Date.today - days + 1
    cond = @project.project_condition(true)
    cond << " AND (tracker_id = #{@tracker.id})" if @tracker
    
    issues_new_by_date ||=  Issue.count(:all, :conditions => ["(#{cond}) AND start_date BETWEEN ? AND ?", date_from, Date.today+1], :group => "start_date", :include => :project, :order => "start_date" )
    issues_close_by_date ||=  Issue.count(:all, :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?  AND #{Issue.table_name}.updated_on BETWEEN ? AND ?", true, date_from, Date.today+1], :group => "#{Issue.table_name}.updated_on", :include => [:project, :status ], :order => "#{Issue.table_name}.updated_on" )

    issues_open_now ||= Issue.count(:all, :include =>  [:project, :status ], :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=? ", false])
    issues_total_now ||= Issue.count(:all, :include =>  [:project ], :conditions => ["(#{cond}) "])

    issues_new   = [0] * days
    issues_close = [0] * days
    issues_open  = [0] * days
    issues_sum   = [0] * days
    issues_label = []
    issues_date  = []

    days.times do |m| 
      issues_date  << date_from+m
      issues_label << (date_from+m).strftime("%m/%d") 
      issues_new_by_date.each do |n| 
        if n.first.to_date===date_from+m
          issues_new[m] += n.last
        end
      end
      issues_close_by_date.each do |n| 
        if n.first.to_date===date_from+m
          issues_close[m] += n.last
        end
      end
    end

    issues_open[days-1] += issues_open_now.to_int;
    issues_sum[days-1]  += issues_total_now.to_int;
    (days-2).downto(0) do |m|
      issues_open[m] = issues_open[m+1]-issues_new[m+1]+issues_close[m+1]
      issues_sum[m]  = issues_sum[m+1]-issues_new[m+1]
    end

    if (Setting.plugin_gompertan_plugin['show_cwday1']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday2']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday3']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday4']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday5']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday6']==='1' or
        Setting.plugin_gompertan_plugin['show_cwday7']==='1' )
      (issues_date.size-1).downto(0) do |m|
        if(not Setting.plugin_gompertan_plugin['show_cwday'+issues_date[m].cwday.to_s]==='1')
          issues_new.delete_at(m)
          issues_close.delete_at(m)
          issues_open.delete_at(m)
          issues_sum.delete_at(m)
          issues_label.delete_at(m)
        end
      end
    end

    graph = SVG::Graph::Line.new(
      :height => 300,
      :width => 600,
      :fields => issues_label,
      :stack => :side,
      :scale_integers => true,
      :step_x_labels => (issues_date.size)/6==0?1:(issues_date.size)/6,
      :show_data_values => false,
      :graph_title => l(:gompertan_graph_title)+"  ("+date_from.strftime("%Y/%m/%d")+" - "+Date.today.strftime("%Y/%m/%d")+")",
      :show_graph_title => true
    )
    
    logger.debug(graph);
    
    graph.add_data(
      :data => issues_sum,
      :title => l(:gompertan_graph_issues_sum)
    )

    graph.add_data(
      :data => issues_new,
      :title => l(:gompertan_graph_issues_new)
    )

    graph.add_data(
      :data => issues_open,
      :title => l(:gompertan_graph_issues_open)
    )
    
    graph.add_data(
      :data => issues_close,
      :title => l(:gompertan_graph_issues_close)
    )
    
    graph.burn
  end

end

# Author:: Miron Cuperman (mailto:miron+cms@google.com)
# Copyright:: Google Inc. 2012
# License:: Apache 2.0

require 'csv'

class ImportException < Exception
end

# HandleSystems
class SystemsController < BaseObjectsController
  include ImportHelper

  SYSTEM_MAP = Hash[*%w(System\ Code slug Title title Description description Link:References references Infrastructure infrastructure Link:People;Owner owner Link:Categories categories Append:Notes append_notes Link:System;Sub\ System sub_systems Link:Org\ Group org_groups Effective\ Date start_date Created created_at Updated updated_at Network\ Zone network_zone)]

  access_control :acl do
    allow :superuser

    actions :new, :create, :import do
      allow :create, :create_system
    end

    allow :read, :read_system, :of => :system, :to => [:show,
                                                       :tooltip]

    actions :edit, :update do
      allow :update, :update_system, :of => :system
    end
  end

  layout 'dashboard'

  # TODO BASE OBJECTS
  # - use abstracted methods to handle 'index' cases

  def index
    @systems = System
    if params[:s].present?
      @systems = @systems.db_search(params[:s])
    end

    @systems = @systems.all

    if params[:as_subsystems_for].present?
      super_system_id = params[:as_subsystems_for].to_i
      if super_system_id.present?
        @systems = @systems.select { |s| s.id != super_system_id }
      end
    end

    render :json => @systems
  end

  def export
    respond_to do |format|
      format.html do
        render :layout => 'export_modal'
      end
      format.csv do
        self.response.headers['Content-Type'] = 'text/csv'
        headers['Content-Disposition'] = "attachment; filename=\"SYSTEMS.csv\""
        self.response_body = Enumerator.new do |out|
          out << CSV.generate_line(%w(Type))
          out << CSV.generate_line(%w(Systems))
          out << CSV.generate_line([])
          out << CSV.generate_line([])
          out << CSV.generate_line(SYSTEM_MAP.keys)
          System.all.each do |s|
            values = SYSTEM_MAP.keys.map do |key|
              field = SYSTEM_MAP[key]
              case field
              when 'owner'
                object_person = s.object_people.detect {|x| x.role == 'accountable'}
                object_person ? object_person.person.email : ''
              when 'categories'
                (s.categories.map {|x| x.name}).join(',')
              when 'sub_systems'
                (s.sub_systems.map {|x| x.slug}).join(',')
              when 'append_notes'
                ""
              when 'org_groups'
                rels = Relationship.where(:relationship_type_id => :system_is_a_process_for_org_group, :source_id => s, :source_type => System.name)
                rels.map {|x| x.destination.slug}.join(',')
              when 'references'
                s.documents.map do |d|
                  "#{d.description} [#{d.link} #{d.title}]"
                end.join("\n")
              else
                s.send(field)
              end
            end
            out << CSV.generate_line(values)
          end
        end
      end
    end
  end

  def import
    upload = params["upload"]
    if upload.present?
      begin
        file = upload.read.force_encoding('utf-8')
        import = read_import_systems(CSV.parse(file))
        @messages = import[:messages]
        do_import(import, params[:confirm].blank?)
        @warnings = import[:warnings]
        @errors = import[:errors]
        @creates = import[:creates]
        @updates = import[:updates]
        render 'import_result', :layout => false
      rescue CSV::MalformedCSVError, ArgumentError => e
        log_backtrace(e)
        render_import_error("Not a recognized file.")
      rescue ImportException => e
        render_import_error("Could not import file: #{e.to_s}")
      rescue => e
        log_backtrace(e)
        render_import_error
      end
    elsif request.post?
      render_import_error("Please select a file.")
    end
  end

  def do_import(import, check_only)
    import[:errors] = {}
    import[:updates] = []
    import[:creates] = []
    import[:warnings] = {}

    @systems = []
    import[:systems].each_with_index do |attrs, i|
      import[:warnings][i] = HashWithIndifferentAccess.new

      attrs.delete(nil)
      attrs.delete('created_at')
      attrs.delete('updated_at')

      handle_import_person(attrs, 'owner', import[:warnings][i])

      slug = attrs['slug']

      if slug.blank?
        import[:warnings][i][:slug] ||= []
        import[:warnings][i][:slug] << "missing system slug"
        system = nil
      else
        system = System.find_by_slug(slug)
      end

      system ||= System.new

      handle_import_object_person(system, attrs, 'owner', 'accountable')
      handle_import_object_person(system, attrs, 'process_owner', 'process_owner')
      handle_import_category(system, attrs, 'categories', System::CATEGORY_TYPE_ID)
      handle_import_sub_systems(system, attrs, 'sub_systems')
      org_groups = attrs.delete('org_groups')
      handle_import_documents(system, attrs, 'references')

      handle_option(attrs, 'network_zone', import[:warnings], :network_zone)
      
      append_notes = attrs.delete('append_notes')
      if append_notes
        splits = (attrs['description'] || system.description || "").split("\n---\n").map {|x| x.strip}
        new_splits = (append_notes ||"").split("\n---\n").map {|x| x.strip}
        new_splits.each do |split|
          splits << split unless splits.include?(split)
        end
        splits = splits.map {|x| x.force_encoding('utf-8')} #FIXME encoding issue on some inputs
        attrs['description'] = splits.join("\n---\n")
      end

      system.assign_attributes(attrs, :without_protection => true)

      if system.new_record?
        import[:creates] << slug
      else
        import[:updates] << slug
      end
      @systems << system
      import[:errors][i] = system.errors unless system.valid?
      system.infrastructure = false if system.infrastructure.nil?
      system.save unless check_only
      handle_import_relationships(system, org_groups, OrgGroup, :system_is_a_process_for_org_group) unless check_only
    end
  end

  def read_import_systems(rows)
    import = { :messages => [] }

    raise ImportException.new("There must be at least 5 input lines") unless rows.size >= 5

    rows.shift
    rows.shift
    rows.shift
    rows.shift

    read_import(import, SYSTEM_MAP, "system", rows)

    import
  end

  private

    def delete_model_stats
      [ [ 'System Control', @system.system_controls.count ],
        [ 'System Section', @system.system_sections.count ]
      ]
    end

    def extra_delete_relationship_stats
      [ [ 'Sub Systems', @system.sub_systems.count ],
        [ 'Super Systems', @system.super_systems.count ],
      ]
    end

    def post_destroy_path
      programs_dash_path
    end

    def system_params
      system_params = params[:system] || {}
      %w(type).each do |field|
        parse_option_param(system_params, field)
      end

      %w(start_date stop_date).each do |field|
        parse_date_param(system_params, field)
      end

      # Fixup legacy boolean
      if system_params[:type]
        system_params[:infrastructure] = system_params[:type].title == 'Infrastructure'
      else
        system_params[:infrastructure] = false
      end

      system_params
    end
end

# Author:: Daniel Ring (mailto:danring+cms@google.com)
# Copyright:: Google Inc. 2012
# License:: Apache 2.0

class CategoriesController < BaseObjectsController

  access_control :acl do
    allow :superuser
  end

  layout 'dashboard'

  no_base_action :tooltip

  def index
    @categories = Category
    if params[:scope_id].present?
      @categories = @categories.ctype(params[:scope_id])
    end
    if params[:root].present? && params[:root] == '1'
      @categories = @categories.where(:parent_id => nil)
    else
      @categories = @categories.leaves
    end
    if params[:s]
      @categories = @categories.db_search(params[:s])
    end
    render :json => @categories.all.as_json
  end

  def export
    respond_to do |format|
      format.csv do
        self.response.headers['Content-Type'] = 'text/csv'
        headers['Content-Disposition'] = "attachment; filename=\"categories.csv\""
        self.response_body = Enumerator.new do |out|
          out << CSV.generate_line(Category.attribute_names_for_csv)

          Category.roots.sort_by(&:display_name).each do |root_category|
            out << root_category.as_csv
            root_category.descendants.sort_by(&:display_name).each do |category|
              out << category.as_csv
            end
          end
        end
      end
    end
  end

  private

    def new_object
      if params[:scope_id]
        ccats = Category.ctype(params[:scope_id])
      else
        ccats = Category
      end
      @category = ccats.new(category_params)
    end

    def base_form_context
      super.merge :scope_id => params[:scope_id]
    end

    def category_params
      category_params = params[:category] || {}
      parent_id = category_params.delete(:parent_id)
      if parent_id.present?
        category_params[:parent] = Category.find(parent_id)
      end
      category_params
    end
end

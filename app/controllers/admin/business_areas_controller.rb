class Admin::BusinessAreasController < ApplicationController
  layout "admin"

  def index
    @business_areas = BusinessArea.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @business_areas }
    end
  end

  def show
    @business_area = BusinessArea.get(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @business_area }
    end
  end

  def new
    @business_area = BusinessArea.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @business_area }
    end
  end

  def edit
    @business_area = BusinessArea.get(params[:id])
  end

  def create
    @business_area = BusinessArea.new(params[:business_area])

    respond_to do |format|
      if @business_area.save
        format.html { redirect_to(edit_business_area_path(@business_area), :notice => 'Biz Process was successfully created.') }
        format.xml  { render :xml => @business_area, :status => :created, :location => @business_area }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @business_area.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @business_area = BusinessArea.get(params[:id])

    respond_to do |format|
      if @business_area.update(params[:business_area])
        format.html { redirect_to(edit_business_area_path(@business_area), :notice => 'Biz Process was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @business_area.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    business_area = BusinessArea.get(params[:id])

    respond_to do |format|
      format.html { redirect_to(business_areas_url) }
      format.xml  { head :ok }
    end
  end

end
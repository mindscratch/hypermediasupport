module HypermediaSupport

  VERSION = "0.0.1"

  require 'hypermedia_support/error'
  require 'hypermedia_support/paging_support'
  require 'hypermedia_support/model_maker'
  require 'hypermedia_support/model_locator'

  include PagingSupport
  extend ModelMaker
  extend ModelLocator
  extend self

  def with(controller, opts={})
    @@controller = controller
    @@opts = configure_opts opts
    self
  end

  def make(type, params=nil)
    mime_type = request.format
    format = mime_type.to_sym
    return invalid_mime_type_response(mime_type) unless valid_mime_type? mime_type

    params = scrub_params(params || request.params)
    do_make(type, params, format)
  end

  def locate(type, id=nil)
    mime_type = request.format
    format = mime_type.to_sym
    return invalid_mime_type_response(mime_type) unless valid_mime_type? mime_type

    do_locate type, id || params[:id], format
  end

  #######
  private
  #######

  def controller
    raise "Controller not defined, please invoke \"with\" first." if defined?(@@controller).nil? || @@controller.nil?
    @@controller
  end

  def request
    controller.request
  end

  def opts
    @@opts
  end

  def configure_opts(opts={})
    {:invalid_mime_type_response_type => :xml}.merge(opts)
  end

  def scrub_params(params, format)
    if params.has_key(format)
      params = params[format]
    end
    params.delete "action"
    params.delete "controller"
    params
  end


  # criteria: ActiveRecord::Relation, Mongoid::Criteria
  def locate_page(criteria, params=nil)
    # TODO in progress
    #   validate mime type

    format = request.format.to_sym
    params = params || controller.params

    if params.has_key?(format)
      params = params[format]
    end
    params.delete "action" if params.has_key? "action"
    params.delete "controller" if params.has_key? "controller"

    page = (params[:page] || 1).to_i
    per_page (params[:per_page] || 10).to_i

    page = 1 if page < 1
    per_page = 10 if per_page < 1
    total_results = criteria.count

    paging_context = do_paging(page, per_page, total_results)
    headers['X-Total-Results'] = paging_context[:total_results].to_s

    criteria = criteria.skip(paging_context[:skip]).limit(paging_context[:limit])

    additional_links = {}
    criteria.each_with_index do |item, index|
      additional_links[index] = controller.url_for(item)
    end
    set_link_header paging_context[:links].merge(additional_links)

    {format => criteria, :status => :ok}
  end

  def valid_mime_type?(mime_type)
    controller.mimes_for_respond_to.keys.include?(mime_type.to_sym)
  end

  def valid_mime_types
    mime_types = controller.mimes_for_respond_to.keys.map do |format|
      ActiveResource::Formats[format.to_sm].mime_type
    end
  end

  def invalid_mime_type_response(mime_type)
    # TODO include list of valid mime types in the error message
    {opts[:invalid_mime_type_response_type].to_sym => Error.new("Invalid mime type #{mime_type.to_s}, acceptable types [#{valid_mime_types.join(', ')}]"), :status => :not_acceptable}
  end

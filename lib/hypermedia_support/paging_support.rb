require 'cgi'
require 'uri'

module HypermediaSupport
  module PagingSupport
    module HumanBased
      def self.included(base)
        base.class_eval do
          define_method(:pageParamName) do
            @pageParamName ||= "page"
          end

          define_method(:"pageParamName=") do |pageParamName|
            @pageParamName = pageParamName
          end

          define_method(:pageParamRegex) do
            @pageParamRegex ||= /#{pageParamName}=\d+/
          end

          define_method(:perPageParamName) do
            @perPageParamName||= "per_page"
          end

          define_method(:"perPageParamName=") do |perPageParamName|
            @perPageParamName= perPageParamName
          end
        end

        def has_next?(page, total_pages)
          page < total_pages
        end

        def has_prev?(page)
          page > 1
        end

        def has_first?(page)
          has_prev? page
        end

        def has_last?(page, total_pages)
          total_pages > 1 && has_next?(page, total_pages)
        end

        def next_page(page)
          page + 1
        end

        def prev_page(page)
          page - 1
        end

        def first_page
          1
        end

        def last_page(total_pages)
          total_pages
        end

        def calculate_total_pages(number_of_items, per_page)
          (number_of_items.to_f / per_page).ceil
        end

        def update_uri(uri, query_params)
          parts = query_params.map do |key, values|
            result = values.map {|val| "#{key}=#{val}"}
            result.join '&'
          end
          uri = uri.dup
          uri.query = parts.join '&'
          uri
        end

        def get_links(page, per_page, total_pages, request_url=nil)
          request_url = URI.parse(request_url || request.url)
          # CGI.parse creates a Hash whose values are arrays which is why perPageParam value is an array
          # instead of just a single value
          query_params = request_url.query.nil? ? {} : CGI.parse(request_url.query)
          query_params[perPageParamName] = [per_page]
          relation_to_url = {}

          if has_next?(page, total_pages)
            query_params[pageParamName] = [next_page(page)]
            relation_to_url[:next] = update_uri(request_url, query_params).to_s
          end

          if has_prev?(page)
            query_params[pageParamName] = [prev_page(page)]
            relation_to_url[:prev] = update_uri(request_url, query_params).to_s
          end

          if has_first?(page)
            query_params[pageParamName] = [first_page]
            relation_to_url[:first] = update_uri(request_url, query_params).to_s
          end

          if has_last?(page, total_pages)
            query_params[pageParamName] = [last_page(total_pages)]
            relation_to_url[:last] = update_uri(request_url, query_params).to_s
          end

          relation_to_url
      end

      def do_paging(page, per_page, total_results)
        total_pages = calculate_total_pages(total_results, per_page)
        skip = (page * per_page) - per_page
        limit = per_page
        links = get_links(page, per_page, total_pages)

        # TODO create a PagingContext class to use instead of a Hash, also update 'zerobased' support
        # to have updated get_links, do_paging stuff.
        {
          page: page,
          per_page: per_page,
          total_results: total_results,
          total_pages: total_pages,
          skip: skip,
          limit: limit,
          links: links
        }
      end
    end
  end
end
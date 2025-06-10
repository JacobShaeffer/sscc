module ContentsHelper
    def log(string)
      puts "\e[38;2;0;255;0m#{string}\e[0m"
    end
    def warn(string)
      puts "\e[38;2;255;255;0m#{string}\e[0m"
    end
    def err(string)
      puts "\e[38;2;255;0;0m#{string}\e[0m"
    end

    def content_filters_form(url:, &block)
        bootstrap_form_with(
            url: url,
            layout: :inline,
            method: :get,
            html: { class: "mb-2" },
            data: {
                controller: "filters",
                filters_target: "form",
                turbo_frame: :content_table
            },
            &block
        )
    end

    def get_filter_values
        {
            title: session.dig('content_filters', :title.to_s) || "",
            display_title: session.dig('content_filters', :display_title.to_s) || "",
            user: session.dig('content_filters', :user.to_s) || "",
            copyright_permission: session.dig('content_filters', :copyright_permission.to_s) || "",
            year_of_publication_from: session.dig('content_filters', :year_of_publication_from.to_s) || "",
            year_of_publication_to: session.dig('content_filters', :year_of_publication_to.to_s) || "",
            description: session.dig('content_filters', :description.to_s) || "",
            filename: session.dig('content_filters', :filename.to_s) || ""
        }
    end

    def content_table_headers
        base_columns = %w[
            title display_title user copyright_permission
            year_of_publication description filename
            created_at updated_at
        ]

        headers = base_columns.map do |column|
            if session.dig("content_filters", "columns")&.include?(column)
                render partial: "sortable-header", locals: {column: column, title: column.titleize}
            end
        end

        metadata_headers = MetadataType.all.map do |metadata_type|
            if session.dig("content_filters", "columns")&.include?(metadata_type.id.to_s)
                render partial: "sortable-header", locals: {column: metadata_type.id.to_s, title: metadata_type.name}
            end
        end.compact

        safe_join(headers + metadata_headers)
    end

    def sortable_link_contents(sort:, label:)
        if sort == session.dig('content_filters','sort')
            link_to(label, list_contents_path(sort: sort, direction: next_direction_contents))
        else
            link_to(label, list_contents_path(sort: sort, direction: 'asc'))
        end
    end

    private

    def next_direction_contents
        case session['content_filters']['direction']
            when 'asc'
                'desc'
            when 'desc'
                'none'
            else
                'asc'
        end
    end
end

module ContentsHelper
    def sortable_link(sort:, label:)
        if sort == session.dig('content_filters','sort')
            link_to(label, list_contents_path(sort: sort, direction: next_direction))
        else
            link_to(label, list_contents_path(sort: sort, direction: 'asc'))
        end
    end

    def sort_indicator()
        direction = session.dig('content_filters', 'direction')
        if direction.present?
            render partial: 'contents/sort_indicator', locals: {direction: direction}
        end
    end

    private

    def next_direction
        # session['content_filters']['direction'] == 'asc' ? 'desc' : 'asc'
        case session['content_filters']['direction']
            when 'asc'
                'desc'
            when 'desc'
                'nil'
            else
                'asc'
        end
    end
end

module ContentsHelper

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

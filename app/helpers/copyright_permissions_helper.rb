module CopyrightPermissionsHelper

    def sortable_link_copyright_permissions(sort:, label:)
        if sort == session.dig('copyright_permission_filters','sort')
            link_to(label, list_copyright_permissions_path(sort: sort, direction: next_direction_copyright_permissions))
        else
            link_to(label, list_copyright_permissions_path(sort: sort, direction: 'asc'))
        end
    end

    private

    def next_direction_copyright_permissions
        # session['content_filters']['direction'] == 'asc' ? 'desc' : 'asc'
        case session['copyright_permission_filters']['direction']
            when 'asc'
                'desc'
            when 'desc'
                'none'
            else
                'asc'
        end
    end
end

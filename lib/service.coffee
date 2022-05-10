if Meteor.isClient
    Router.route '/services', (->
        @layout 'layout'
        @render 'services'
        ), name:'services'
    Router.route '/service/:doc_id/edit', (->
        @layout 'layout'
        @render 'service_edit'
        ), name:'service_edit'
    Router.route '/service/:doc_id', (->
        @layout 'layout'
        @render 'service_view'
        ), name:'service_view'
    
    
    # Template.services.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'service', ->
    Template.services.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

        # @autorun => @subscribe 'model_docs', 'service', ->
        @autorun => @subscribe 'results',
            'service'
            picked_tags.array()
            Session.get('current_query')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')

    Template.service_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.service_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.service_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.services.events
        'click .add_service': ->
            new_id = 
                Docs.insert 
                    model:'service'
            Router.go "/service/#{new_id}/edit"
    Template.service_card.events
        'click .view_service': ->
            Router.go "/service/#{@_id}"
    Template.service_item.events
        'click .view_service': ->
            Router.go "/service/#{@_id}"

    Template.service_edit.events
        'click .delete_service': ->
            Swal.fire({
                title: "delete service?"
                text: "cannot be undone"
                icon: 'question'
                confirmButtonText: 'delete'
                confirmButtonColor: 'red'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'service removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/service"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish service?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_service', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'service published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish service?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_service', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'service unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'service_count', (
        picked_ingredients
        picked_sections
        service_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'service'}
        if picked_ingredients.length > 0
            match.ingredients = $all: picked_ingredients
            # sort = 'price_per_serving'
        if picked_sections.length > 0
            match.menu_section = $all: picked_sections
            # sort = 'price_per_serving'
        # else
            # match.tags = $nin: ['wikipedia']
        sort = '_timestamp'
            # match.source = $ne:'wikipedia'
        if view_vegan
            match.vegan = true
        if view_gf
            match.gluten_free = true
        if service_query and service_query.length > 1
            console.log 'searching service_query', service_query
            match.title = {$regex:"#{service_query}", $options: 'i'}
        Counts.publish this, 'service_counter', Docs.find(match)
        return undefined
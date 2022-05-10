if Meteor.isClient
    Router.route '/mailers', (->
        @layout 'layout'
        @render 'mailers'
        ), name:'mailers'
    Router.route '/mailer/:doc_id/edit', (->
        @layout 'layout'
        @render 'mailer_edit'
        ), name:'mailer_edit'
    Router.route '/mailer/:doc_id', (->
        @layout 'layout'
        @render 'mailer_view'
        ), name:'mailer_view'
    Router.route '/mailer/:doc_id/view', (->
        @layout 'layout'
        @render 'mailer_view'
        ), name:'mailer_view_long'
    
    
    # Template.mailers.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'mailer', ->
    Template.mailers.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.mailers.onCreated ->
        @autorun => @subscribe 'mailer_results',
            picked_tags.array()
            Session.get('current_query')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_delivery')
            Session.get('view_pickup')
            Session.get('view_open')

    Template.mailer_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.mailer_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.mailer_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.mailers.helpers
        mailer_docs: ->
            Docs.find {
                model:'mailer'
            }, sort:_timestamp:-1
        tag_results: ->
            Results.find 
                model:'mailer_tag'
        picked_mailer_tags: -> picked_tags.array()
        
                
    Template.mailers.events
        'click .add_mailer': ->
            new_id = 
                Docs.insert 
                    model:'mailer'
            Router.go "/mailer/#{new_id}/edit"
    Template.mailer_card.events
        'click .view_mailer': ->
            Router.go "/mailer/#{@_id}"
    Template.mailer_item.events
        'click .view_mailer': ->
            Router.go "/mailer/#{@_id}"

    
    Template.mailer_edit.events
        'click .delete_mailer': ->
            Swal.fire({
                title: "delete mailer?"
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
                        title: 'mailer removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/mailer"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish mailer?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_mailer', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'mailer published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish mailer?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_mailer', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'mailer unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
            
if Meteor.isServer            
    Meteor.publish 'mailer_count', (
        picked_ingredients
        picked_sections
        mailer_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'mailer'}
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
        if mailer_query and mailer_query.length > 1
            console.log 'searching mailer_query', mailer_query
            match.title = {$regex:"#{mailer_query}", $options: 'i'}
        Counts.publish this, 'mailer_counter', Docs.find(match)
        return undefined

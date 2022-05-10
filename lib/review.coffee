if Meteor.isClient
    Template.reviews_widget.onCreated ->
        @autorun => @subscribe 'model_docs', 'review', ->
    
    
    
    Template.reviews_widget.helpers
        review_docs: ->
            Docs.find   
                model:'review'


    Router.route '/reviews', (->
        @layout 'layout'
        @render 'reviews'
        ), name:'reviews'
    Router.route '/review/:doc_id/edit', (->
        @layout 'layout'
        @render 'review_edit'
        ), name:'review_edit'
    Router.route '/review/:doc_id', (->
        @layout 'layout'
        @render 'review_view'
        ), name:'review_view'
    Router.route '/review/:doc_id/view', (->
        @layout 'layout'
        @render 'review_view'
        ), name:'review_view_long'
    
    
    # Template.reviews.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'review', ->
    Template.reviews.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.reviews.onCreated ->
        # @autorun => @subscribe 'model_docs', 'review', ->
        @autorun => @subscribe 'results',
            'review'
            picked_tags.array()
            Session.get('current_query')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')

    Template.review_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.review_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.review_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.reviews.events
        'click .add_review': ->
            new_id = 
                Docs.insert 
                    model:'review'
            Router.go "/review/#{new_id}/edit"
    Template.review_card.events
        'click .view_review': ->
            Router.go "/review/#{@_id}"

    
    Template.review_edit.events
        'click .delete_review': ->
            Swal.fire({
                title: "delete review?"
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
                        title: 'review removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/review"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish review?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_review', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'review published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish review?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_review', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'review unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'review_count', (
        picked_ingredients
        picked_sections
        review_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'review'}
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
        if review_query and review_query.length > 1
            console.log 'searching review_query', review_query
            match.title = {$regex:"#{review_query}", $options: 'i'}
        Counts.publish this, 'review_counter', Docs.find(match)
        return undefined

if Meteor.isClient
    Template.testimonials_widget.onCreated ->
        @autorun => @subscribe 'model_docs', 'testimonial', ->
    
    
    
    Template.testimonials_widget.helpers
        testimonial_docs: ->
            Docs.find   
                model:'testimonial'


    Router.route '/testimonials', (->
        @layout 'layout'
        @render 'testimonials'
        ), name:'testimonials'
    Router.route '/testimonial/:doc_id/edit', (->
        @layout 'layout'
        @render 'testimonial_edit'
        ), name:'testimonial_edit'
    Router.route '/testimonial/:doc_id', (->
        @layout 'layout'
        @render 'testimonial_view'
        ), name:'testimonial_view'
    Router.route '/testimonial/:doc_id/view', (->
        @layout 'layout'
        @render 'testimonial_view'
        ), name:'testimonial_view_long'
    
    
    # Template.testimonials.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'testimonial', ->
    Template.testimonials.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.testimonials.onCreated ->
        # @autorun => @subscribe 'model_docs', 'testimonial', ->
        @autorun => @subscribe 'results',
            'testimonial'
            picked_tags.array()
            Session.get('current_query')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')

    Template.testimonial_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.testimonial_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.testimonial_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.testimonials.events
        'click .add_testimonial': ->
            new_id = 
                Docs.insert 
                    model:'testimonial'
            Router.go "/testimonial/#{new_id}/edit"
    Template.testimonial_card.events
        'click .view_testimonial': ->
            Router.go "/testimonial/#{@_id}"

    
    Template.testimonial_edit.events
        'click .delete_testimonial': ->
            Swal.fire({
                title: "delete testimonial?"
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
                        title: 'testimonial removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/testimonial"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish testimonial?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_testimonial', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'testimonial published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish testimonial?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_testimonial', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'testimonial unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'testimonial_count', (
        picked_ingredients
        picked_sections
        testimonial_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'testimonial'}
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
        if testimonial_query and testimonial_query.length > 1
            console.log 'searching testimonial_query', testimonial_query
            match.title = {$regex:"#{testimonial_query}", $options: 'i'}
        Counts.publish this, 'testimonial_counter', Docs.find(match)
        return undefined

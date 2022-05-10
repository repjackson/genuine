if Meteor.isClient
    Template.faqs_widget.onCreated ->
        @autorun => @subscribe 'model_docs', 'faq', ->
    
    
    
    Template.faqs_widget.helpers
        faq_docs: ->
            Docs.find   
                model:'faq_docs'


    Router.route '/faqs', (->
        @layout 'layout'
        @render 'faqs'
        ), name:'faqs'
    Router.route '/faq/:doc_id/edit', (->
        @layout 'layout'
        @render 'faq_edit'
        ), name:'faq_edit'
    Router.route '/faq/:doc_id', (->
        @layout 'layout'
        @render 'faq_view'
        ), name:'faq_view'
    Router.route '/faq/:doc_id/view', (->
        @layout 'layout'
        @render 'faq_view'
        ), name:'faq_view_long'
    
    
    # Template.faqs.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'faq', ->
    Template.faqs.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.faqs.onRendered ->
        Meteor.setTimeout ->
            $('.accordion').accordion()
        , 1000
        
    Template.faqs.onCreated ->
        @autorun => @subscribe 'results',
            'faq'
            picked_tags.array()
            Session.get('current_query')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_delivery')
            Session.get('view_pickup')
            Session.get('view_open')

    Template.faq_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.faq_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.faq_item.onCreated ->
        # @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.faqs.helpers
        faq_docs: ->
            Docs.find {
                model:'faq'
            }, sort:_timestamp:-1
        tag_results: ->
            Results.find 
                model:'faq_tag'
        picked_faq_tags: -> picked_tags.array()
        
                
    Template.faqs.events
        'click .add_faq': ->
            new_id = 
                Docs.insert 
                    model:'faq'
            Router.go "/faq/#{new_id}/edit"
    Template.faq_item.events
        'click .view_faq': ->
            Router.go "/faq/#{@_id}"

    
    Template.faq_edit.events
        'click .delete_faq': ->
            Swal.fire({
                title: "delete faq?"
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
                        title: 'faq removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/faq"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish faq?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_faq', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'faq published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish faq?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_faq', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'faq unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'faq_count', (
        picked_ingredients
        picked_sections
        faq_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'faq'}
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
        if faq_query and faq_query.length > 1
            console.log 'searching faq_query', faq_query
            match.title = {$regex:"#{faq_query}", $options: 'i'}
        Counts.publish this, 'faq_counter', Docs.find(match)
        return undefined

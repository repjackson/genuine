if Meteor.isClient
    Router.route '/organizations', (->
        @layout 'layout'
        @render 'organizations'
        ), name:'organizations'
    Router.route '/organization/:doc_id/edit', (->
        @layout 'layout'
        @render 'organization_edit'
        ), name:'organization_edit'
    Router.route '/organization/:doc_id', (->
        @layout 'layout'
        @render 'organization_view'
        ), name:'organization_view'
    
    
    # Template.organizations.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'org', ->
    Template.organizations.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

        @autorun => @subscribe 'model_docs', 'organization', ->

    Template.organizations.onCreated ->
        @autorun => @subscribe 'results',
            'organization'
            picked_tags.array()
            Session.get('current_query')
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_delivery')
            Session.get('view_pickup')
            Session.get('view_open')

    Template.organization_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.organization_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.organization_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.organizations.helpers
                
    Template.organizations.events
        'click .add_organization': ->
            new_id = 
                Docs.insert 
                    model:'organization'
            Router.go "/organization/#{new_id}/edit"
    Template.organization_card.events
        'click .view_org': ->
            Router.go "/organization/#{@_id}"
    Template.organization_item.events
        'click .view_org': ->
            Router.go "/organization/#{@_id}"

    
    
    Template.organization_edit.events
        'click .delete_org': ->
            Swal.fire({
                title: "delete org?"
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
                        title: 'org removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/organizations"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish org?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_org', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'org published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish org?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_org', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'org unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
            
            
    Meteor.publish 'org_count', (
        picked_ingredients
        picked_sections
        org_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'organization'}
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
        if org_query and org_query.length > 1
            console.log 'searching org_query', org_query
            match.title = {$regex:"#{org_query}", $options: 'i'}
        Counts.publish this, 'org_counter', Docs.find(match)
        return undefined

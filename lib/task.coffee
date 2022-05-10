if Meteor.isClient
    Router.route '/tasks', (->
        @layout 'layout'
        @render 'tasks'
        ), name:'tasks'
    Router.route '/task/:doc_id/edit', (->
        @layout 'layout'
        @render 'task_edit'
        ), name:'task_edit'
    Router.route '/task/:doc_id', (->
        @layout 'layout'
        @render 'task_view'
        ), name:'task_view'
    Router.route '/task/:doc_id/view', (->
        @layout 'layout'
        @render 'task_view'
        ), name:'task_view_long'
    
    
    # Template.tasks.onCreated ->
    Template.tasks.onCreated ->
        @autorun => Meteor.subscribe 'model_logs', 'log', ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.tasks.onCreated ->
        @autorun => @subscribe 'results',
            'task'
            picked_tags.array()
            Session.get('current_query')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')

    Template.task_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->
        @autorun => @subscribe 'model_docs','log', ->
        @autorun => @subscribe 'task_children',Router.current().params.doc_id, ->
        @autorun => @subscribe 'model_docs','task', ->

        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.task_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'all_users', ->
    Template.task_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.tasks.helpers
        task_docs: ->
            Docs.find 
                model:'task'
    Template.tasks.events
        'click .add_task': ->
            new_id = 
                Docs.insert 
                    model:'task'
            Router.go "/task/#{new_id}/edit"
    Template.task_card.events
        'click .view_task': ->
            Router.go "/task/#{@_id}"
    Template.task_item.events
        'click .view_task': ->
            Router.go "/task/#{@_id}"

    Template.task_view.events
        'click .add_subtask': ->
            new_id = 
                Docs.insert 
                    model:'task'
                    parent_id:@_id
            Router.go "/task/#{new_id}/edit"

        'click .mark_complete': ->
            Docs.update Router.current().params.doc_id, 
                $set:
                    complete:true
                    complete_timestamp:Date.now()
            new_id = 
                Docs.insert 
                    model:'log'
                    parent_model:'task'
                    body: "#{@title} marked complete at #{moment(Date.now()).format('dddd, MMMM Do h:mm a')} by #{Meteor.user().username}"
                    task_id:Router.current().params.doc_id
                    parent_id:Router.current().params.doc_id
            console.log 'new log message about', @title
    Template.task_edit.events
        'click .delete_task': ->
            Swal.fire({
                title: "delete task?"
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
                        title: 'task removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/task"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish task?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_task', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'task published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish task?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_task', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'task unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer            
    Meteor.publish 'model_logs', (model)->
        Docs.find {
            model:'log'
            parent_model:model
        }, 
            limit:20
            sort:_timestamp:-1
        
    Meteor.publish 'task_count', (
        picked_ingredients
        picked_sections
        task_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'task'}
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
        if task_query and task_query.length > 1
            console.log 'searching task_query', task_query
            match.title = {$regex:"#{task_query}", $options: 'i'}
        Counts.publish this, 'task_counter', Docs.find(match)
        return undefined



if Meteor.isClient
    Template.task_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'

    Template.task_card.helpers
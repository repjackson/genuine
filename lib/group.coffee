Router.route '/group/:doc_id', (->
    @layout 'layout'
    @render 'group_view'
    ), name:'group_view'


if Meteor.isClient
    Template.group_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
        # @autorun => Meteor.subscribe 'children', 'group_update', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'group_members', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'group_leaders', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'group_events', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'group_posts', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'group_products', Router.current().params.doc_id, ->
    Template.group_view.onRendered ->
        Meteor.call 'log_view', Router.current().params.doc_id, ->
    
    Template.group_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->


    # Template.groups_small.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'group', Sesion.get('group_search'),->
    # Template.groups_small.helpers
    #     group_docs: ->
    #         Docs.find   
    #             model:'group'
                
                
                
    Template.group_view.helpers
        group_events: ->
            Docs.find 
                model:'event'
                group_ids:$in:[Router.current().params.doc_id]
        group_posts: ->
            Docs.find 
                model:'post'
                # group_ids:$in:[Router.current().params.doc_id]
        # current_group: ->
        #     Docs.findOne
        #         model:'group'
        #         slug: Router.current().params.doc_id

    Template.group_shop.events
        'click .add_product': ->
            new_id = 
                Docs.insert 
                    model:'product'
                    group_id:Router.current().params.doc_id
                    
            Router.go "/product/#{new_id}/edit"
            
    Template.group_view.events
        'click .add_group_task': ->
            new_id = 
                Docs.insert 
                    model:'task'
                    group_id:Router.current().params.doc_id
                    
            Router.go "/task/#{new_id}/edit"
            
        
        'click .refresh_group_stats': ->
            Meteor.call 'calc_group_stats', Router.current().params.doc_id, ->
        'click .add_group_event': ->
            new_id = 
                Docs.insert 
                    model:'event'
                    group_ids:[Router.current().params.doc_id]
            Router.go "/event/#{new_id}/edit"
        'click .add_group_post': ->
            new_id = 
                Docs.insert 
                    model:'post'
                    group_ids:[Router.current().params.doc_id]
            Router.go "/post/#{new_id}/edit"
        # 'click .join': ->
        #     Docs.update
        #         model:'group'
        #         _author_id: Meteor.userId()
        # 'click .group_leave': ->
        #     my_group = Docs.findOne
        #         model:'group'
        #         _author_id: Meteor.userId()
        #         ballot_id: Router.current().params.doc_id
        #     if my_group
        #         Docs.update my_group._id,
        #             $set:value:'no'
        #     else
        #         Docs.insert
        #             model:'group'
        #             ballot_id: Router.current().params.doc_id
        #             value:'no'


if Meteor.isServer
    Meteor.publish 'group_events', (group_id)->
        # group = Docs.findOne
        #     model:'group'
        #     _id:group_id
        Docs.find
            model:'event'
            group_ids:$in: [group_id]

    Meteor.publish 'group_posts', (group_id)->
        # group = Docs.findOne
        #     model:'group'
        #     _id:group_id
        Docs.find
            model:'post'
            group_ids:$in: [group_id]


    Meteor.publish 'group_leaders', (group_id)->
        group = Docs.findOne group_id
        if group.leader_ids
            Meteor.users.find
                _id: $in: group.leader_ids

    Meteor.publish 'group_members', (group_id)->
        group = Docs.findOne group_id
        Meteor.users.find
            _id: $in: group.member_ids




Router.route '/group/:doc_id/edit', -> @render 'group_edit'


# group edit
if Meteor.isClient
    Template.group_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'group_options', Router.current().params.doc_id
    Template.group_edit.events
        'click .add_option': ->
            Docs.insert
                model:'group_option'
                ballot_id: Router.current().params.doc_id
    Template.group_edit.helpers
        options: ->
            Docs.find
                model:'group_option'


# groups
if Meteor.isClient
    Router.route '/groups', (->
        @layout 'layout'
        @render 'groups'
        ), name:'groups'


    Template.groups.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'member_count'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true

    Template.groups.onCreated ->
        @autorun => @subscribe 'results',
            'group'
            picked_tags.array()
            Session.get('current_query')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')


    Template.groups.events
        'click .add_group': ->
            new_id =
                Docs.insert
                    model:'group'
            Router.go("/group/#{new_id}/edit")

        'click .calc_group_count': ->
            Meteor.call 'calc_group_count', ->

        # 'keydown #search': _.throttle((e,t)->
        #     if e.which is 8
        #         search = $('#search').val()
        #         if search.length is 0
        #             last_val = picked_tags.array().slice(-1)
        #             console.log last_val
        #             $('#search').val(last_val)
        #             picked_tags.pop()
        #             Meteor.call 'search_reddit', picked_tags.array(), ->
        # , 1000)


if Meteor.isClient
    Meteor.methods
        calc_group_stats: ->
            group_stat_doc = Docs.findOne(model:'group_stats')
            unless group_stat_doc
                new_id = Docs.insert
                    model:'group_stats'
                group_stat_doc = Docs.findOne(model:'group_stats')
            console.log group_stat_doc
            total_count = Docs.find(model:'group').count()
            complete_count = Docs.find(model:'group', complete:true).count()
            incomplete_count = Docs.find(model:'group', complete:$ne:true).count()
            Docs.update group_stat_doc._id,
                $set:
                    total_count:total_count
                    complete_count:complete_count
                    incomplete_count:incomplete_count

if Meteor.isServer
    Meteor.publish 'user_groups', (username)->
        user = Meteor.users.findOne username:username
        Docs.find
            model:'group'
            _author_id: user._id

    Meteor.publish 'group_by_slug', (group_slug)->
        Docs.find
            model:'group'
            slug:group_slug
    Meteor.methods
        calc_group_stats: (group_slug)->
            group = Docs.findOne
                model:'group'
                slug: group_slug

            member_count =
                group.member_ids.length

            group_members =
                Meteor.users.find
                    _id: $in: group.member_ids

            dish_count = 0
            dish_ids = []
            for member in group_members.fetch()
                member_dishes =
                    Docs.find(
                        model:'dish'
                        _author_id:member._id
                    ).fetch()
                for dish in member_dishes
                    console.log 'dish', dish.title
                    dish_ids.push dish._id
                    dish_count++
            # dish_count =
            #     Docs.find(
            #         model:'dish'
            #         group_id:group._id
            #     ).count()
            group_count =
                Docs.find(
                    model:'group'
                    group_id:group._id
                ).count()

            order_cursor =
                Docs.find(
                    model:'order'
                    group_id:group._id
                )
            order_count = order_cursor.count()
            total_credit_exchanged = 0
            for order in order_cursor.fetch()
                if order.order_price
                    total_credit_exchanged += order.order_price
            group_groups =
                Docs.find(
                    model:'group'
                    group_id:group._id
                ).fetch()

            console.log 'total_credit_exchanged', total_credit_exchanged


            Docs.update group._id,
                $set:
                    member_count:member_count
                    group_count:group_count
                    dish_count:dish_count
                    total_credit_exchanged:total_credit_exchanged
                    dish_ids:dish_ids
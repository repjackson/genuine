if Meteor.isClient
    Template.recalc_stats_button.events
        'click .recalc': ->
            console.log 'recalc'
            Meteor.call 'calc_stats', ->
    Template.doc_array_toggle.helpers
        user_list_toggle_class: ->
            if Session.get('current_user')
                parent = Template.parentData()
                if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then '' else 'basic'
            else
                'disabled'
        in_list: ->
            parent = Template.parentData()
            if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then true else false
        list_users: ->
            parent = Template.parentData()
            Docs.find _id:$in:parent["#{@key}"]


    Template.calc_user_stats_button.events 
        'click .recalc': ->
            console.log 'calc user', @username
            Meteor.call 'calc_user_stats', @_id, ->

    Template.add_doc_button.events
        'click .add_doc': ->
            if @model
                new_id = 
                    Docs.insert 
                        model:@model
                Router.go "/#{@model}/#{new_id}/edit"

    Template.toggle_sort_direction.events 
        'click .toggle': ->
            if Session.equals 'sort_direction', -1
                Session.set 'sort_direction', 1
                $('body').toast({
                    title: "sort direction set up"
                    # message: 'Please see desk staff for key.'
                    class : 'success'
                    icon:'sort direction up'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })
            else
                Session.set 'sort_direction', -1
                $('body').toast({
                    title: "sort direction set down"
                    # message: 'Please see desk staff for key.'
                    class : 'success'
                    icon:'sort direction down'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })

    Template.facet.onCreated ->
        # console.log @
        @autorun => @subscribe 'facets',
            @data.model
            picked_tags.array()
            Session.get('current_query')
    
    Template.facet.helpers
        tag_results: ->
            Results.find {}
                # model:'tag'
        picked_tags: -> picked_tags.array()
    Template.facet.events 
        'click .pick_tag': -> picked_tags.push @name
        'click .unpick_tag': -> picked_tags.remove @valueOf()
    
    Template.fans.helpers
        is_fan: -> Meteor.userId() and @fan_user_ids and Meteor.userId() in @fan_user_ids
        fan_user_docs: ->
            Meteor.users.find 
                _id:$in:@fan_user_ids
                
                
    Template.fans.events
        'click .become_fan': ->
            if Meteor.userId()
                Docs.update Router.current().params.doc_id, 
                    $addToSet:
                        fan_user_ids:Meteor.userId()
                Meteor.users.update Meteor.userId(),
                    $inc:points:10
            else 
                Router.go "/login"
        'click .unfan': ->
            Docs.update Router.current().params.doc_id, 
                $pull:
                    fan_user_ids:Meteor.userId()
                Meteor.users.update Meteor.userId(),
                    $inc:points:-10
            
    
    Template.favorite_icon_toggle.helpers
        icon_class: ->
            if @favorite_ids and Meteor.userId() in @favorite_ids
                'red'
            else
                'outline'
    Template.favorite_icon_toggle.events
        'click .toggle_fav': ->
            if @favorite_ids and Meteor.userId() in @favorite_ids
                Docs.update @_id, 
                    $pull:favorite_ids:Meteor.userId()
            else
                $('body').toast(
                    showIcon: 'heart'
                    message: "marked favorite"
                    showProgress: 'bottom'
                    class: 'success'
                    # displayTime: 'auto',
                    position: "bottom right"
                )

                Docs.update @_id, 
                    $addToSet:favorite_ids:Meteor.userId()
        
    Template.comments.onRendered ->
        Meteor.setTimeout ->
            $('.accordion').accordion()
        , 1000
    Template.comments.onCreated ->
        # if Router.current().params.doc_id
        #     parent = Docs.findOne Router.current().params.doc_id
        @autorun => Meteor.subscribe 'children', 'comment', Router.current().params.doc_id, ->
        # else
        #     parent = Docs.findOne Template.parentData()._id
        # if parent
    Template.comments.helpers
        doc_comments: ->
            if Router.current().params.doc_id
                parent = Docs.findOne Router.current().params.doc_id
            else
                parent = Docs.findOne Template.parentData()._id
            Docs.find
                parent_id:parent._id
                model:'comment'
    Template.print_this.events
        'click .print': -> console.log @
    Template.comments.events
        'keyup .add_comment': (e,t)->
            if e.which is 13
                if Router.current().params.doc_id
                    parent = Docs.findOne Router.current().params.doc_id
                else
                    parent = Docs.findOne Template.parentData()._id
                # parent = Docs.findOne Router.current().params.doc_id
                comment = t.$('.add_comment').val()
                Docs.insert
                    parent_id: parent._id
                    model:'comment'
                    parent_model:parent.model
                    body:comment
                t.$('.add_comment').val('')

        'click .remove_comment': ->
            if confirm 'Confirm remove comment'
                Docs.remove @_id


    Template.viewing_info.helpers
        viewers: ->
            Meteor.users.find 
                _id:$in:@viewer_user_ids



    Template.send_points_button.events
        'click .send_coin': ->
            console.log @
            new_id = 
                Docs.insert 
                    model:'transfer'
                    target_user_id:@_id
                    target_username:@username
            Router.go "/transfer/#{new_id}/edit"



    Template.follow.helpers
        followers: ->
            Docs.find
                _id: $in: @follower_ids
        following: -> @follower_ids and Meteor.userId() in @follower_ids
    Template.follow.events
        'click .follow': ->
            Docs.update @_id,
                $addToSet:follower_ids:Meteor.userId()
        'click .unfollow': ->
            Docs.update @_id,
                $pull:follower_ids:Meteor.userId()
   
   

    Template.voting.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @, ->
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @, ->


    Template.voting_small.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @, ->
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @, ->


    # Template.doc_card.onCreated ->
    #     @autorun => Meteor.subscribe 'doc', Template.currentData().doc_id
    # Template.doc_card.helpers
    #     doc: ->
    #         Docs.findOne
    #             _id:Template.currentData().doc_id




    Template.voting_full.events
        'click .upvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'upvote', @
        'click .downvote': (e,t)->
            $(e.currentTarget).closest('.button').transition('pulse',200)
            Meteor.call 'downvote', @



    Template.group_picker.onCreated ->
        @autorun => @subscribe 'group_search_results', Session.get('group_search'), ->
        @autorun => @subscribe 'model_docs', 'group', ->
    Template.group_picker.helpers
        group_results: ->
            Docs.find 
                model:'group'
                title: {$regex:"#{Session.get('group_search')}",$options:'i'}
                
        group_search_value: ->
            Session.get('group_search')
        
    Template.group_picker.events
        'click .clear_search': (e,t)->
            Session.set('group_search', null)
            t.$('.group_search').val('')

            
        'click .remove_group': (e,t)->
            # if confirm "remove #{@title} group?"
            Docs.update Router.current().params.doc_id,
                $unset:
                    group_id:@_id
                    group_title:@title
        'click .pick_group': (e,t)->
            Docs.update Router.current().params.doc_id,
                $set:
                    group_id:@_id
                    group_title:@title
            Session.set('group_search',null)
            t.$('.group_search').val('')
                    
        'keyup .group_search': (e,t)->
            # if e.which is '13'
            val = t.$('.group_search').val()
            console.log val
            Session.set('group_search', val)

        'click .create_group': ->
            new_id = 
                Docs.insert 
                    model:'group'
                    title:Session.get('group_search')
            Router.go "/group/#{new_id}/edit"


if Meteor.isServer 
    Meteor.publish 'group_search_results', (group_title_queary)->
        Docs.find 
            model:'group'
            title: {$regex:"#{group_title_queary}",$options:'i'}
        
if Meteor.isClient
    Template.search_input.helpers
        current_search: -> Session.get('current_search')
    Template.search_input.events
        'click .clear_search': (e,t)->
            Session.set('current_search', null)
            t.$('.current_search').val('')
            $('body').toast({
                title: "search cleared"
                # message: 'Please see desk staff for key.'
                class : 'info'
                icon:'remove'
                position:'bottom right'
                # className:
                #     toast: 'ui massive message'
                # displayTime: 5000
                transition:
                  showMethod   : 'zoom',
                  showDuration : 250,
                  hideMethod   : 'fade',
                  hideDuration : 250
                })
    
    
        'keyup .search': _.throttle((e,t)->
            query = $('.query').val()
            Session.set('current_search', query)
            
            console.log Session.get('current_search')
            if e.which is 13
                search = $('.query').val().trim().toLowerCase()
                if search.length > 0
                    picked_tags.push search
                    console.log 'search', search
                    # Meteor.call 'log_term', search, ->
                    $('.search').val('')
                    Session.set('current_search', null)
                    # # $( "p" ).blur();
                    # Meteor.setTimeout ->
                    #     Session.set('dummy', !Session.get('dummy'))
                    # , 10000
        , 500)
    
    
    Template.session_set.events
        'click .set_session_value': -> 
            console.log @key, @value
            Session.set(@key, @value)

    Template.session_set.helpers
        calculated_class: ->
            if Session.equals(@key, @value) then 'active large' else 'compact basic'
    Template.sort_direction_toggle.events 
        'click .toggle': ->
            if Session.equals 'sort_direction', -1
                Session.set 'sort_direction', 1
                $('body').toast({
                    title: "sort direction set up"
                    # message: 'Please see desk staff for key.'
                    class : 'success'
                    icon:'sort direction up'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })
            else
                Session.set 'sort_direction', -1
                $('body').toast({
                    title: "sort direction set down"
                    # message: 'Please see desk staff for key.'
                    class : 'success'
                    icon:'sort direction down'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })
    




    # Template.set_limit.events
    #     'click .set_limit': ->
    #         Session.set('limit',parseInt(@amount))



    Template.big_user_card.onCreated ->
        @autorun => Meteor.subscribe 'user_from_username', @data
    Template.big_user_card.helpers
        user: -> Docs.findOne username:@valueOf()



    Template.sort_direction_toggle.events
        'click .set_sort_direction': ->
            if Session.get('sort_direction') is -1
                Session.set('sort_direction', 1)
            else
                Session.set('sort_direction', -1)




    Template.username_info.onCreated ->
        @autorun => Meteor.subscribe 'user_from_username', @data
    Template.username_info.events
        'click .goto_profile': ->
            user = Docs.findOne username:@valueOf()
            if user.is_current_member
                Router.go "/member/#{user.username}/"
            else
                Router.go "/user/#{user.username}/"
    Template.username_info.helpers
        user: -> Docs.findOne username:@valueOf()




    Template.user_info.onCreated ->
        @autorun => Meteor.subscribe 'user_from_id', @data
    Template.user_info.helpers
        user_doc: -> Docs.findOne @valueOf()


    Template.toggle_edit.events
        'click .toggle_edit': ->
            console.log @
            console.log Template.currentData()
            console.log Template.parentData()
            console.log Template.parentData(1)
            console.log Template.parentData(2)
            console.log Template.parentData(3)
            console.log Template.parentData(4)




    Template.user_list_info.onCreated ->
        @autorun => Meteor.subscribe 'user', @data

    Template.user_list_info.helpers
        user: ->
            console.log @
            Docs.findOne @valueOf()



    Template.user_field.helpers
        key_value: ->
            user = Docs.findOne Router.current().params.doc_id
            user["#{@key}"]

    Template.user_field.events
        'blur .user_field': (e,t)->
            value = t.$('.user_field').val()
            Docs.update Router.current().params.doc_id,
                $set:"#{@key}":value


    Template.user_list_toggle.onCreated ->
        @autorun => Meteor.subscribe 'user_list', Template.parentData(),@key
    Template.user_list_toggle.events
        'click .toggle': (e,t)->
            parent = Template.parentData()
            $(e.currentTarget).closest('.button').transition('pulse',200)
            if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"]
                Docs.update parent._id,
                    $pull:"#{@key}":Meteor.userId()
            else
                Docs.update parent._id,
                    $addToSet:"#{@key}":Meteor.userId()
    Template.user_list_toggle.helpers
        user_list_toggle_class: ->
            if Session.get('current_user')
                parent = Template.parentData()
                if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then '' else 'basic'
            else
                'disabled'
        in_list: ->
            parent = Template.parentData()
            if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then true else false
        list_users: ->
            parent = Template.parentData()
            Docs.find _id:$in:parent["#{@key}"]


    Template.doc_array_togggle.helpers
        user_list_toggle_class: ->
            if Session.get('current_user')
                parent = Template.parentData()
                if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then '' else 'basic'
            else
                'disabled'
        in_list: ->
            parent = Template.parentData()
            if parent["#{@key}"] and Meteor.userId() in parent["#{@key}"] then true else false
        list_users: ->
            parent = Template.parentData()
            Docs.find _id:$in:parent["#{@key}"]



    Template.viewing.events
        'click .mark_read': (e,t)->
            unless @read_user_ids and Meteor.userId() in @read_user_ids
                Meteor.call 'mark_read', @_id, ->
                    # $(e.currentTarget).closest('.comment').transition('pulse')
                    $('.unread_icon').transition('pulse')
        'click .mark_unread': (e,t)->
            Docs.update @_id,
                $inc:views:-1
            Meteor.call 'mark_unread', @_id, ->
                # $(e.currentTarget).closest('.comment').transition('pulse')
                $('.unread_icon').transition('pulse')
    Template.viewing.helpers
        viewed_by: -> 
            if @read_user_ids 
                Meteor.userId() in @read_user_ids
        readers: ->
            readers = []
            if @read_user_ids
                for reader_id in @read_user_ids
                    unless reader_id is @author_id
                        readers.push Docs.findOne reader_id
            readers



    Template.email_validation_check.events
        'click .send_verification': ->
            console.log @
            if confirm 'send verification email?'
                Meteor.call 'verify_email', @_id, ->
                    alert 'verification email sent'
        'click .toggle_email_verified': ->
            console.log @emails[0].verified
            if @emails[0]
                Docs.update @_id,
                    $set:"emails.0.verified":true


    Template.set_sort_key.helpers
        sort_key_class: -> if Session.equals('sort_key',@key) then 'blue' else ''
    Template.set_sort_key.events
        'click .set_key': (e,t)->
            console.log @
            Session.set('sort_key', @key)
            Session.set('sort_label', @label)
            Session.set('sort_icon', @icon)


    Template.remove_button.events
        'click .remove_doc': (e,t)->
            if confirm "remove #{@model}?"
                if $(e.currentTarget).closest('.card')
                    $(e.currentTarget).closest('.card').transition('fly right', 1000)
                else
                    $(e.currentTarget).closest('.segment').transition('fly right', 1000)
                    $(e.currentTarget).closest('.item').transition('fly right', 1000)
                    $(e.currentTarget).closest('.content').transition('fly right', 1000)
                    $(e.currentTarget).closest('tr').transition('fly right', 1000)
                    $(e.currentTarget).closest('.event').transition('fly right', 1000)
                Meteor.setTimeout =>
                    Docs.remove @_id
                , 1000

    Template.remove_icon.events
        'click .remove_doc': (e,t)->
            if confirm "remove #{@model}?"
                if $(e.currentTarget).closest('.card')
                    $(e.currentTarget).closest('.card').transition('fly right', 1000)
                else
                    $(e.currentTarget).closest('.segment').transition('fly right', 1000)
                    $(e.currentTarget).closest('.item').transition('fly right', 1000)
                    $(e.currentTarget).closest('.content').transition('fly right', 1000)
                    $(e.currentTarget).closest('tr').transition('fly right', 1000)
                    $(e.currentTarget).closest('.event').transition('fly right', 1000)
                Meteor.setTimeout =>
                    Docs.remove @_id
                , 1000

    Template.view_user_button.events
        'click .view_user': ->
            Router.go "/user/#{username}"


    # Template.session_edit_value_button.events
    #     'click .set_session_value': ->
    #         # console.log @key
    #         # console.log @value
    #         Session.set(@key, @value)

    # Template.session_edit_value_button.helpers
    #     calculated_class: ->
    #         res = ''
    #         # console.log @
    #         if @cl
    #             res += @cl
    #         if Session.equals(@key,@value)
    #             res += ' active'
    #         else 
    #             res += ' basic'
    #         # console.log res
    #         res



    Template.session_boolean_toggle.events
        'click .toggle_session_key': ->
            console.log @key
            Session.set(@key, !Session.get(@key))

    Template.session_boolean_toggle.helpers
        calculated_class: ->
            res = ''
            # console.log @
            if @cl
                res += @cl
            if Session.get(@key)
                res += ' blue'
            else
                res += ' '

            # console.log res
            res

if Meteor.isServer
    Meteor.publish 'children', (model, parent_id, limit)->
        # console.log model
        # console.log parent_id
        limit = if limit then limit else 10
        Docs.find {
            model:model
            parent_id:parent_id
        }, limit:limit
        
        
if Meteor.isClient
    Template.doc_array_togggle.helpers
        doc_array_toggle_class: ->
            parent = Template.parentData()
            # user = Docs.findOne Router.current().params.username
            if parent["#{@key}"] and @value in parent["#{@key}"] then 'active' else 'basic'
    Template.doc_array_togggle.events
        'click .toggle': (e,t)->
            parent = Template.parentData()
            console.log 'key', @key, @value
            console.log 'parent', parent
            if parent["#{@key}"]
                if @value in parent["#{@key}"]
                    Docs.update parent._id,
                        $pull: "#{@key}":@value
                else
                    Docs.update parent._id,
                        $addToSet: "#{@key}":@value
            else
                Docs.update parent._id,
                    $addToSet: "#{@key}":@value




Meteor.methods
    mark_read: (doc_id)->
        doc = Docs.findOne doc_id
        Docs.update doc_id,
            $addToSet:
                read_user_ids: Meteor.userId()
            $set:
                last_viewed: Date.now() 
            $inc:views:1
    mark_unread: (doc_id)->
        doc = Docs.findOne doc_id
        Docs.update doc_id,
            $pull:
                read_user_ids: Meteor.userId()
            $inc:views:-1





if Meteor.isClient
    Template.session_key_value_edit.events
        'click .set_key_value': ->
            console.log 'hi'
            # parent = Template.parentData()
            # Docs.update parent._id,
            #     $set: "#{@key}": @value
            if Session.equals('sort_direction',-1)
                Session.set('sort_direction',1)
            else 
                Session.set('sort_direction',-1)
            Session.set("#{@key}",@value)
            
            
    Template.session_key_value_edit.helpers
        set_key_value_class: ->
            parent = Template.parentData()
            # console.log parent
            # if parent["#{@key}"] is @value then 'active' else ''
            if Session.equals("#{@key}",@value) then 'active large' else 'basic'
    
    
    
            
    Template.key_value_edit.helpers
        set_key_value_class: ->
            parent = Template.parentData()
            # console.log parent
            # if parent["#{@key}"] is @value then 'active' else ''
            if parent["#{@key}"] is @value then 'active large' else 'basic'
    
    
    Template.key_value_edit.events
        'click .set_key_value': ->
            # console.log 'hi'
            parent = Template.parentData()
            # console.log parent, @key, @value
            if Docs.findOne parent._id
                Docs.update parent._id,
                    $set: "#{@key}": @value
            # else if
            #     Docs.update parent._id,
            #         $set: "#{@key}": @value
            else
                Meteor.users.update parent._id, 
                    $set: "#{@key}": @value
            $('body').toast(
                showIcon: 'checkmark'
                message: "updated #{@key}:#{@value}"
                showProgress: 'bottom'
                class: 'success'
                # displayTime: 'auto',
                position: "bottom right"
            )
                
                


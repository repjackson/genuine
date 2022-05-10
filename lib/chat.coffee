Meteor.methods
    create_chat: (tags=[])->
        Docs.insert
            tags: tags
            model: 'chat_channel'
            subscribers: [Meteor.userId()]
            member_ids: [Meteor.userId()]
        # Router.go "/chat/#{id}"

    close_chat: (chat_id)->
        Docs.remove chat_id
        Docs.remove
            model: 'message'
            channel_id: chat_id

    join_chat: (chat_id)->
        Docs.update chat_id,
            $addToSet:
                member_ids: Meteor.userId()

    leave_chat: (chat_id)->
        Docs.update chat_id,
            $pull:
                member_ids: Meteor.userId()



if Meteor.isClient
    Template.chat.onCreated ->
        @autorun -> Meteor.subscribe('model_docs', 'message')
        @autorun -> Meteor.subscribe('chat_channels', picked_tags.array(), picked_member_ids.array())
        @view_published = new ReactiveVar(true)

    Template.chat.helpers
        channel_docs: ->
            if Template.instance().view_published.get() is true
                Docs.find {
                    model: 'chat_channel'
                    published: true
                }, sort: timestamp: -1
            else
                Docs.find {
                    member_ids: $in: [Meteor.userId()]
                    model: 'chat_channel'
                    published: -1
                }, sort: timestamp: -1

        selected_chat: ->
            Docs.findOne Session.get 'current_chat_id'

        unread_message_count: ->
            count = 0
            my_chats = Docs.find(
                model: 'chat_channel'
                member_ids: $in: [Meteor.userId()]
            ).fetch()

            for chat in my_chats
                unread_count = Docs.find(
                    model: 'message'
                    # channel_id: chat._id
                    read_ids: $nin: [Meteor.userId()]
                ).count()
                count += unread_count
            count


        viewing_published: -> Template.instance().view_published.get() is true
        viewing_private: -> Template.instance().view_published.get() is false



    Template.chat.events
        'click .create_channel': ->
            Meteor.call 'create_chat', (err,id)->
                Session.set 'current_chat_id', id

        'click #create_dm': ->
            Meteor.call 'create_', (err,id)->
                Session.set 'current_chat_id', id

                # Router.go "/view/#{id}"


    # 'click #create_chat': ->
    #     id = Docs.insert
    #         model: 'chat'
    #         member_ids: [Meteor.userId()]
    #     Router.go "/chat/#{id}"


        'click #view_private_chats': (e,t)->
            t.view_published.set(false)

        'click #view_published_chats': (e,t)->
            t.view_published.set(true)





if Meteor.isServer
    Meteor.publish 'people_list', (chat_id) ->
        chat = Docs.findOne chat_id
        Meteor.users.find
            _id: $in: chat.member_ids


    # Meteor.publish 'chat_messages', (chat_id) ->
    #     Docs.find
    #         model: 'message'
    #         chat_id: chat_id


    # publishComposite 'member_ids', (picked_tags, picked_member_ids)->

    #     {
    #         find: ->
    #             self = @
    #             match = {}
    #             match.model = 'chat'
    #             if picked_tags.length > 0 then match.tags = $all: picked_tags
    #             if picked_member_ids.length > 0 then match.member_ids = $in: picked_member_ids
    #             match.published = true

    #             cloud = Docs.aggregate [
    #                 { $match: match }
    #                 { $project: member_ids: 1 }
    #                 { $unwind: "$member_ids" }
    #                 { $group: _id: '$member_ids', count: $sum: 1 }
    #                 { $match: _id: $nin: picked_member_ids }
    #                 { $sort: count: -1, _id: 1 }
    #                 { $limit: 20 }
    #                 { $project: _id: 0, text: '$_id', count: 1 }
    #                 ]



    #             # author_objects = []
    #             # Meteor.users.find _id: $in: cloud.

    #             cloud.forEach (member_ids) ->
    #                 self.added 'member_ids', Random.id(),
    #                     text: member_ids.text
    #                     count: member_ids.count
    #             self.ready()

    #         # children: [
    #         #     { find: (doc) ->
    #         #         Meteor.users.find
    #         #             _id: doc.member_ids
    #         #         }
    #         #     ]
    #     }


    Meteor.publish 'chat_channels', (picked_tags, picked_member_ids, view_published)->
        self = @
        match = {}
        if picked_tags.length > 0 then match.tags = $all: picked_tags
        # if view_published is true
        #     match.published = 1
        #     if picked_member_ids.length > 0 then match.member_ids = $in: picked_member_ids
        # else if view_published = false
        #     match.published = -1
        #     picked_member_ids.push Meteor.userId()
        #     match.member_ids = $in: picked_member_ids
        # if view_mode
        #     if view_mode is 'mine'
        #         match
        #         match.member_ids = $in: [Meteor.userId()]
        # else
            # if picked_member_ids.length > 0 then match.member_ids = $in: picked_member_ids
        unless Meteor.userId()
            match.private = $ne:true

        match.model = 'chat_channel'

        cursor = Docs.find match
        return cursor
        
        
if Meteor.isClient
    Router.route '/chat', -> @render 'chat'

    @picked_member_ids = new ReactiveArray []
    Template.chat.onCreated ->
        @autorun => Meteor.subscribe 'all_users', ->

    Template.view_chat.events
        'click .join_chat': (e,t)->
            Meteor.call 'join_chat', @_id, ->
        'click .leave_chat': (e,t)->
            Meteor.call 'leave_chat', @_id, ->

        'click .close_chat': (e,t)->
            self = @
            swal {
                title: "close channel?"
                text: 'this will delete all the messages'
                model: 'warning'
                showCancelButton: true
                animation: true
                confirmButtonColor: '#DD6B55'
                confirmButtonText: 'close'
                closeOnConfirm: true
            }, ->
                message_count =
                    Docs.find({
                        model: 'message'
                        channel_id: self._id }).count()
                # $('.comment').transition(
                #     animation: 'fly right'
                #     duration: 1000
                #     interval: 200
                #     onComplete: ()=>
                Meteor.setTimeout =>
                    Meteor.call 'close_chat', self._id, ->
                , 1000
                # )

                # swal "Submission Removed", "",'success'
                return



    Template.view_chat.helpers
        member_docs: ->
            members = []
            for member_id in @member_ids
                members.push Meteor.users.findOne member_id
            members

        chat_messages: ->
            Docs.find {
                model: 'message'
                channel_id: @_id },
                sort: timestamp: -1

        in_chat: -> if Meteor.userId() in @member_ids then true else false

        message_count: ->
            Docs.find({
                model: 'message'
                channel_id: @_id }).count()

        unread_message_count: ->
            Docs.find({
                model: 'message'
                channel_id: @_id
                read_ids: $nin: [Meteor.userId()]}).count()


        # subscribed: ->
        #     @_id in Docs.findOne(Router.current().params._id).subscribers


    Template.chat_messages_pane.onCreated ->
        # @autorun => Meteor.subscribe 'doc', @data._id
        # @autorun => Meteor.subscribe 'classroom_docs', @data._id
        @autorun => Meteor.subscribe 'people_list', @data._id

    Template.chat_messages_pane.helpers
        in_chat: ->
            if Meteor.user()
                if Meteor.userId() in @member_ids then true else false
        chat_messages: ->
            Docs.find {
                model: 'message'
                channel_id: @_id },
                sort: _timestamp: 1

        chat_tag_class:-> if @valueOf() in selected_chat_tags.array() then 'black' else ''

        chat: -> Docs.findOne @_id


    Template.chat_messages_pane.events
        'keydown .add_message': (e,t)->
            e.preventDefault
            if e.which is 13
                channel_id = @_id
                body = t.find('.add_message').value.trim()
                if body.length > 0
                    Meteor.call 'add_message', body, channel_id, (err,res)=>
                        if err then console.error err
                        else
                    $('.add_message').transition('bounce')
                    t.find('.add_message').value = ''

    # Template.edit_chat.events
    #     'click #delete_doc': ->
    #         if confirm 'Delete this chat?'
    #             Docs.remove @_id
    #             Router.go '/chat'

if Meteor.isServer
    Meteor.methods
        add_message: (body,channel_id)->
            new_message_id = Docs.insert
                body: body
                model: 'message'
                channel_id: channel_id
                read_ids:[Meteor.userId()]
                tags: ['chat', 'message']

            chat_doc = Docs.findOne _id: channel_id
            message_doc = Docs.findOne new_message_id
            message_author = Meteor.users.findOne message_doc.author_id

            # message_link = "https://www.joyful-giver.com/chat"

            # this.unblock()

            # offline_ids = []
            # for member_id in chat_doc.member_ids
            #     user = Meteor.users.findOne member_id
            #     if user.status.online is true
            #     else
            #         offline_ids.push user._id


            # for offline_id in offline_ids
            #     offline_user = Meteor.users.findOne offline_id

            #     Email.send
            #         to: " #{offline_user.profile.first_name} #{offline_user.profile.last_name} <#{offline_user.emails[0].address}>",
            #         from: "Joyful Giver Admin <no-reply@joyful-giver.com>",
            #         subject: "New Message from #{message_author.profile.first_name} #{message_author.profile.last_name}",
            #         html:
            #             "<h4>#{message_author.profile.first_name} just sent the following message while you were offline: </h4>
            #             #{body} <br><br>

            #             Click <a href=#{message_link}> here to view.</a><br><br>
            #             You can unsubscribe from this chat in the Actions panel.
            #             "

                    # html:
                    #     "<h4>#{message_author.profile.first_name} just sent the following message: </h4>
                    #     #{text} <br>
                    #     In chat with tags: #{chat_doc.tags}. \n
                    #     In chat with description: #{chat_doc.description}. \n
                    #     \n
                    #     Click <a href="/view/#{_id}"
                    # "
            # return new_message_id

if Meteor.isClient
    Template.chat.onCreated ->
        # @autorun => Meteor.subscribe 'my_chats'
        @autorun => Meteor.subscribe 'docs', picked_tags.array(), 'chat_channel', ->
    Template.chat_channel.onCreated ->
        # @autorun => Meteor.subscribe 'classroom_docs', @data._id
        @autorun => Meteor.subscribe 'people_list', @data._id


    Template.chat.helpers
        channel_docs: ->
            Docs.find
                model: 'chat_channel'
                # member_ids: $in: [Meteor.userId()]

        message_segment_class: -> if Meteor.userId() in @read_ids then 'basic' else ''
        read: -> @read_ids and Meteor.userId() in @read_ids

    Template.chat_channel.helpers
        members: ->
            members = []
            for member_id in @member_ids
                members.push Meteor.users.findOne member_id
            members

        last_message: ->
            Docs.findOne {
                model: 'message'
                channel_id: @_id
            },
                sort: timestamp: -1
                limit: 1

        chat_list_item_class: -> if Session.equals 'current_chat_id', @_id then 'inverted blue' else ''

    Template.chat.events
        'click .chat_list_item': (e,t)->
            Session.set 'current_chat_id', @_id

        'click .mark_unread': (e,t)->
            Meteor.call 'mark_unread', @_id, ->
                $(e.currentTarget).closest('.message_segment').transition('pulse')


if Meteor.isClient
    Template.chat_message.onRendered ->
        # Meteor.setTimeout ->
        #     $('.ui.accordion').accordion()
        # , 500


    Template.chat_message.helpers
        message_segment_class: -> if Meteor.userId() in @read_ids then 'basic' else ''
        read: -> Meteor.userId() in @read_ids

        readers: ->
            readers = []
            if @read_ids
                for reader_id in @read_ids
                    unless reader_id is @author_id
                        readers.push Meteor.users.findOne reader_id
            readers


    Template.chat_message.events
        'click .delete_message': (e,t)->
            if confirm 'Delete message?'
                $(e.currentTarget).closest('.comment').transition('fly right')
                Meteor.setTimeout =>
                    Docs.remove @_id
                , 1000


        'click .mark_read, click .text': (e,t)->
            unless @read_ids and Meteor.userId() in @read_ids
                Meteor.call 'mark_read', @_id, ->
                    # $(e.currentTarget).closest('.comment').transition('pulse')
                    $('.unread_icon').transition('pulse')
        'click .mark_unread': (e,t)->
            Meteor.call 'mark_unread', @_id, ->
                # $(e.currentTarget).closest('.comment').transition('pulse')
                $('.unread_icon').transition('pulse')



if Meteor.isServer
    Meteor.publish 'my_chats', ->
        Docs.find
            model: 'chat'
            # member_ids: $in: [Meteor.userId()]        
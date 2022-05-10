if Meteor.isClient
    Template.global_activity.onCreated ->
        @autorun => @subscribe 'model_docs','log',20,->
    
    Template.global_activity.helpers
        latest_log_docs: ->
            Docs.find {
                # model:$ne:'chat_message'
                model:'log'
                # private:$ne:true
            }, sort:_timestamp:-1
    Template.home.helpers
        homepage_data_doc: ->
            doc = 
                Docs.findOne 
                    model:'stat'
        latest_post_docs: ->
            Docs.find {
                model:'post'
                private:$ne:true
            }, sort:_timestamp:-1
        top_users: ->
            Meteor.users.find {},
                sort:points:-1
                
    Template.public_chat.helpers
        latest_chat_docs: ->
            Docs.find {
                model:'chat_message'
            }, sort:_timestamp:-1
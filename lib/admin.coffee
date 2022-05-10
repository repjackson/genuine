if Meteor.isClient
    Router.route '/admin', (->
        @layout 'layout'
        @render 'admin'
        ), name:'admin'

    Router.route '/add', -> @render 'add'
    Template.add_button_big.events
        'click .add_model': ->
            new_id = 
                Docs.insert 
                    model:@model
            Router.go "/#{@model}/#{new_id}/edit"

    Template.admin.onCreated ->
        @autorun => @subscribe 'model_docs', 'admin', ->
            
    Template.admin.helpers
        query_doc: ->
            Docs.findOne 
                model:'admin'



    Template.admin.events
        'click .run_query': ->
            qd = 
                Docs.findOne
                    model:'admin'
            if qd
                console.log 'admin doc', qd
            unless qd
                Docs.insert 
                    model:'admin'
                    
        'click .test_query': ->
            qd = 
                Docs.findOne
                    model:'admin'
            if qd
                console.log 'admin doc', qd
                Meteor.call 'test_admin_query', ->
                    
                    
if Meteor.isServer
    Meteor.methods 
        test_admin_query: ->
            qd = Docs.findOne model:'admin'
            count = 
                Docs.find("#{qd.query_key}":"#{qd.query_value}").count()
            Docs.update qd._id, 
                $set:query_count:count
                    
                    
                    
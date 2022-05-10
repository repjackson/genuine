if Meteor.isClient
    Router.route '/about', (->
        @layout 'layout'
        @render 'about'
        ), name:'about'
    Router.route '/contact', (->
        @layout 'layout'
        @render 'contact'
        ), name:'contact'
    Router.route '/terms', (->
        @layout 'layout'
        @render 'terms'
        ), name:'terms'
    Router.route '/get_started/', (->
        @layout 'get_started_layout'
        @render 'get_started1'
        ), name:'get_started'
    Router.route '/get_started/1', (->
        @layout 'get_started_layout'
        @render 'get_started1'
        ), name:'get_started1'
    Router.route '/get_started/2', (->
        @layout 'get_started_layout'
        @render 'get_started2'
        ), name:'get_started2'
    Router.route '/get_started/3', (->
        @layout 'get_started_layout'
        @render 'get_started3'
        ), name:'get_started3'
    Router.route '/get_started/4', (->
        @layout 'get_started_layout'
        @render 'get_started4'
        ), name:'get_started4'
        
    Template.faqs.onCreated ->
    Template.page.onCreated ->
        @autorun => @subscribe 'page_doc', @data.key, ->
            
    Template.page.events
        'click .create_doc': ->
            new_id = 
                Docs.insert 
                    model:'post'
                    key:@key
            Router.go "/post/#{new_id}/edit"
            
            
    Template.page.helpers
        page_doc: ->
            Docs.findOne 
                model:'post'
                key:@key
            
if Meteor.isServer
    Meteor.publish 'page_doc', (key)->
        Docs.find 
            model:'post'
            key:key

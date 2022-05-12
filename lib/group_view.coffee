if Meteor.isClient 
    Template.checkin_widget.onCreated ->
        @autorun => @subscribe 'model_docs', 'checkin', ->
    Template.checkin_widget.events 
        'click .checkin': ->
            Docs.insert 
                model:'checkin'
    Template.checkin_widget.helpers
        checkin_docs: ->
            Docs.find 
                model:'checkin'
        
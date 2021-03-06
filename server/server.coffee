Docs.allow
    insert: (userId, doc) -> 
        true    
            # doc._author_id is userId
    update: (userId, doc) ->
        doc
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     true
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     true
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) ->
        true
        # doc._author_id is userId or 'admin' in Meteor.user().roles
Meteor.users.allow
    insert: (userId, doc) -> 
        true    
            # doc._author_id is userId
    update: (userId, doc) ->
        doc
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     true
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     true
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) -> Meteor.user() and Meteor.user().admin

Meteor.publish 'count', ->
  Counts.publish this, 'product_counter', Docs.find({model:'product'})
  return undefined    # otherwise coffeescript returns a Counts.publish
                      # handle when Meteor expects a Mongo.Cursor object.


Cloudinary.config
    cloud_name: 'facet'
    api_key: Meteor.settings.private.cloudinary_key
    api_secret: Meteor.settings.private.cloudinary_secret



Meteor.publish 'results', (
    model='post'
    picked_tags=[]
    current_query=''
    picked_timestamp_tags=[]
    picked_location_tags=[]
    sort_key='_timestamp'
    sort_direction=-1
    limit=42
    )->
    self = @
    match = {model:model}
    # if picked_ingredients.length > 0
    #     match.ingredients = $all: picked_ingredients
    #     # sort = 'price_per_serving'
    # if picked_sections.length > 0
    #     match.menu_section = $all: picked_sections
        # sort = 'price_per_serving'
    # else
        # match.tags = $nin: ['wikipedia']
    # match.published = true
        # match.source = $ne:'wikipedia'
    # if view_vegan
    #     match.vegan = true
    # if view_gf
    #     match.gluten_free = true
    if current_query.length > 1
    #     console.log 'searching org_query', org_query
        match.title = {$regex:"#{current_query}", $options: 'i'}
    #     # match.tags_string = {$regex:"#{query}", $options: 'i'}

    # match.tags = $all: picked_ingredients
    # if filter then match.model = filter
    # keys = _.keys(prematch)
    # for key in keys
    #     key_array = prematch["#{key}"]
    #     if key_array and key_array.length > 0
    #         match["#{key}"] = $all: key_array
        # console.log 'current facet filter array', current_facet_filter_array

    # console.log 'sort key', sort_key
    # console.log 'sort direction', sort_direction
    unless Meteor.userId()
        match.private = $ne:true
        
    # console.log 'results match', match
    Docs.find match,
        sort:"#{sort_key}":sort_direction
        limit: limit
        # sort:_timestamp:-1


Meteor.publish 'model_from_child_id', (child_id)->
    child = Docs.findOne child_id
    Docs.find
        model:'model'
        slug:child.type


Meteor.publish 'model_fields_from_child_id', (child_id)->
    child = Docs.findOne child_id
    model = Docs.findOne
        model:'model'
        slug:child.type
    Docs.find
        model:'field'
        parent_id:model._id

Meteor.publish 'model_docs', (
    model
    limit=20
    )->
    Docs.find {
        model: model
        # app:'goldrun'
    }, 
        limit:limit
        sort:_timestamp:-1

Meteor.publish 'document_by_slug', (slug)->
    Docs.find
        model: 'document'
        slug:slug

Meteor.publish 'child_docs', (id)->
    Docs.find
        parent_id:id

Meteor.publish 'me', (id)->
    Meteor.users.find Meteor.userId()


Meteor.publish 'facet_doc', (tags)->
    split_array = tags.split ','
    Docs.find
        tags: split_array

Meteor.publish 'latest_rentals', (tags)->
    Docs.find({
        model:'rental'
    },{
        sort:_timestamp:-1
        limit:10
    })    

Meteor.publish 'inline_doc', (slug)->
    Docs.find
        model:'inline_doc'
        slug:slug



Meteor.publish 'user_from_username', (username)->
    Meteor.users.find 
        username:username

Meteor.publish 'user_from_id', (user_id)->
    Docs.find user_id

Meteor.publish 'doc_by_id', (doc_id)->
    Docs.find doc_id
Meteor.publish 'doc', (doc_id)->
    Docs.find doc_id

Meteor.publish 'author_from_doc_id', (doc_id)->
    doc = Docs.findOne doc_id
    Meteor.users.find doc._author_id

Meteor.publish 'unread_logs', ()->
    Docs.find 
        model:'log'
        read_user_ids:$nin:[Meteor.userId()]
Meteor.publish 'all_users', (slug)->
    Meteor.users.find()
Meteor.publish 'page', (slug)->
    if slug
        Docs.find
            model:'page'
            slug:slug



Meteor.publish 'some_rentals', ->
    Docs.find {
        model:'rental'
        app:'goldrun'
    }, limit:10
    
    
Meteor.methods
    log_event: (body, username)->
        if body
            new_id = 
                Docs.insert 
                    model:'log'
                    body:body
                    username:username
            console.log 'made new log event', body, username
                    
    increment_view: (doc_id)->
        Docs.update doc_id,
            $inc:
                views:1
            $set:
                last_viewed_timestamp:Date.now()


    insert_log: (type, user_id)->
        if type
            new_id = 
                Docs.insert 
                    model:'log_event'
                    log_type:type
                    user_id:user_id
    
    add_user: (username)->
        options = {}
        options.username = username

        res= Accounts.createUser options
        if res
            return res
        else
            Throw.new Meteor.Error 'err creating user'

    parse_keys: ->
        cursor = Docs.find
            model:'key'
        for key in cursor.fetch()
            # new_building_number = parseInt key.building_number
            new_unit_number = parseInt key.unit_number
            Docs.update key._id,
                $set:
                    unit_number:new_unit_number


    change_username:  (user_id, new_username) ->
        user = Docs.findOne user_id
        Accounts.setUsername(user._id, new_username)
        return "updated username to #{new_username}."


    add_email: (user_id, new_email) ->
        Accounts.addEmail(user_id, new_email);
        Accounts.sendVerificationEmail(user_id, new_email)
        return "updated email to #{new_email}"

    remove_email: (user_id, email)->
        # user = Docs.findOne username:username
        Accounts.removeEmail user_id, email


    verify_email: (user_id, email)->
        user = Docs.findOne user_id
        console.log 'sending verification', user.username
        Accounts.sendVerificationEmail(user_id, email)

    validate_email: (email) ->
        re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        re.test String(email).toLowerCase()


    lookup_user: (username_query)->
        # if role_filter
        #     Docs.find({
        #         username: {$regex:"#{username_query}", $options: 'i'}
        #         roles:$in:[role_filter]
        #         },{limit:10}).fetch()
        # else
        Meteor.users.find({
            username: {$regex:"#{username_query}", $options: 'i'}
            },{limit:10}).fetch()


    lookup_doc: (guest_name, model_filter)->
        Docs.find({
            model:model_filter
            guest_name: {$regex:"#{guest_name}", $options: 'i'}
            },{limit:10}).fetch()


    # lookup_username: (username_query)->
    #     found_users =
    #         Docs.find({
    #             model:'person'
    #             username: {$regex:"#{username_query}", $options: 'i'}
    #             }).fetch()
    #     found_users

    # lookup_first_name: (first_name)->
    #     found_people =
    #         Docs.find({
    #             model:'person'
    #             first_name: {$regex:"#{first_name}", $options: 'i'}
    #             }).fetch()
    #     found_people
    #
    # lookup_last_name: (last_name)->
    #     found_people =
    #         Docs.find({
    #             model:'person'
    #             last_name: {$regex:"#{last_name}", $options: 'i'}
    #             }).fetch()
    #     found_people


    set_password: (user_id, new_password)->
        console.log 'setting password', user_id, new_password
        Accounts.setPassword(user_id, new_password)



    global_remove: (keyname)->
        result = Docs.update({"#{keyname}":$exists:true}, {
            $unset:
                "#{keyname}": 1
                "_#{keyname}": 1
            $pull:_keys:keyname
            }, {multi:true})


    count_key: (key)->
        count = Docs.find({"#{key}":$exists:true}).count()




    slugify: (doc_id)->
        doc = Docs.findOne doc_id
        slug = doc.title.toString().toLowerCase().replace(/\s+/g, '_').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '_').replace(/^-+/, '').replace(/-+$/,'')
        return slug
        # # Docs.update { _id:doc_id, fields:field_object },
        # Docs.update { _id:doc_id, fields:field_object },
        #     { $set: "fields.$.slug": slug }


    rename: (old, newk)->
        old_count = Docs.find({"#{old}":$exists:true}).count()
        new_count = Docs.find({"#{newk}":$exists:true}).count()
        console.log 'old count', old_count
        console.log 'new count', new_count
        result = Docs.update({"#{old}":$exists:true}, {$rename:"#{old}":"#{newk}"}, {multi:true})
        result2 = Docs.update({"#{old}":$exists:true}, {$rename:"_#{old}":"_#{newk}"}, {multi:true})

        # > Docs.update({doc_sentiment_score:{$exists:true}},{$rename:{doc_sentiment_score:"sentiment_score"}},{multi:true})
        cursor = Docs.find({newk:$exists:true}, { fields:_id:1 })

        for doc in cursor.fetch()
            Meteor.call 'key', doc._id

    send_enrollment_email: (user_id, email)->
        user = Docs.findOne(user_id)
        console.log 'sending enrollment email to username', user.username
        Accounts.sendEnrollmentEmail(user_id)
    
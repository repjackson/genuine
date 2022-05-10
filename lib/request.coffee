if Meteor.isClient
    Router.route '/request/:doc_id/', (->
        @render 'request_view'
        ), name:'request_view'
    Template.request_view.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'rental_by_res_id', Router.current().params.doc_id


    # Template.rental_view_requests.onCreated ->
    #     @autorun -> Meteor.subscribe 'rental_requests',
    #         Template.currentData()
    #         Session.get 'res_view_mode'
    #         Session.get 'date_filter'
    # Template.rental_view_requests.helpers
    #     requests: ->
    #         Docs.find {
    #             model:'request'
    #         }, sort: start_datetime:-1
    #     view_res_cards: -> Session.equals 'res_view_mode', 'cards'
    #     view_res_segments: -> Session.equals 'res_view_mode', 'segments'
    # Template.rental_view_requests.events
    #     'click .set_card_view': -> Session.set 'res_view_mode', 'cards'
    #     'click .set_segment_view': -> Session.set 'res_view_mode', 'segments'

    Template.request_view.onCreated ->
        @autorun => Meteor.subscribe 'log_events', Router.current().params.doc_id, ->

    # Template.rental_stats.onRendered ->
    #     Meteor.setTimeout ->
    #         $('.accordion').accordion()
    #     , 1000

    # Template.rental_view_requests.onRendered ->
    #     Session.setDefault 'view_mode', 'cards'


    # Template.set_date_filter.events
    #     'click .set_date_filter': -> Session.set 'date_filter', @key
    #
    # Template.set_date_filter.helpers
    #     date_filter_class: ->
    #         if Session.equals('date_filter', @key) then 'active' else ''


if Meteor.isServer
    # Meteor.publish 'rental_requests', (rental, view_mode, date_filter)->
    #     console.log view_mode
    #     console.log date_filter
    #     Docs.find
    #         model:'request'
    #         rental_id: rental._id


    Meteor.publish 'log_events', (parent_id)->
        Docs.find
            model:'log'
            parent_id:parent_id

    Meteor.publish 'requests_by_product_id', (product_id)->
        Docs.find
            model:'request'
            product_id:product_id

    Meteor.publish 'rental_by_res_id', (res_id)->
        request = Docs.findOne res_id
        if request
            Docs.find
                model:'rental'
                _id: request.rental_id

    Meteor.publish 'owner_by_res_id', (res_id)->
        request = Docs.findOne res_id
        rental =
            Docs.findOne
                model:'rental'
                _id: request.rental_id

        Docs.find
            _id: rental.owner_username


    Meteor.methods
        calc_request_stats: ->
            request_stat_doc = Docs.findOne(model:'request_stats')
            unless request_stat_doc
                new_id = Docs.insert
                    model:'request_stats'
                request_stat_doc = Docs.findOne(model:'request_stats')
            console.log request_stat_doc
            total_count = Docs.find(model:'request').count()
            submitted_count = Docs.find(model:'request', submitted:true).count()
            current_count = Docs.find(model:'request', current:true).count()
            unsubmitted_count = Docs.find(model:'request', submitted:$ne:true).count()
            Docs.update request_stat_doc._id,
                $set:
                    total_count:total_count
                    submitted_count:submitted_count
                    current_count:current_count



if Meteor.isClient
    Router.route '/request/:doc_id/edit', (->
        @render 'request_edit'
        ), name:'request_edit'

    Template.request_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'rental_by_res_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'owner_by_res_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'handler_by_res_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'user_by_username', 'deb_sclar'
    Template.request_edit.onRendered =>
        Meteor.call 'log_edit_view', Router.current().params.doc_id, ->
        if Meteor.user()
            Meteor.call 'calc_user_points', Meteor.user().username, ->



    Template.request_edit.helpers
        now_button_class: -> if @now then 'active' else ''
        sel_hr_class: -> if @duration_type is 'hour' then 'active' else ''
        sel_day_class: -> if @duration_type is 'day' then 'active' else ''

        is_paying: -> Session.get 'paying'

        can_buy: ->
            Meteor.user().points > @amount

        need_credit: ->
            Meteor.user().points < @amount


        submit_button_class: ->
            if @start_datetime and @end_datetime then '' else 'disabled'

        point_balance_after_request: ->
            # rental = Docs.findOne @rental_id
            if @amount 
                Meteor.user().points + @amount
            # if rental
            #     current_balance = Meteor.user().points
            #     (current_balance-@total_cost).toFixed(2)

        # diff: -> moment(@end_datetime).diff(moment(@start_datetime),'hours',true)

    # Template.request_edit.events
    #     'click .add_credit': ->
    #         deposit_amount = Math.abs(parseFloat($('.adding_credit').val()))
    #         stripe_charge = parseFloat(deposit_amount)*100*1.02+20
    #         # stripe_charge = parseInt(deposit_amount*1.02+20)

    #         # if confirm "add #{deposit_amount} credit?"
    #         Template.instance().checkout.open
    #             name: 'credit deposit'
    #             # email:Meteor.user().emails[0].address
    #             description: 'gold run'
    #             amount: stripe_charge

    #     'click .trigger_recalc': ->
    #         Meteor.call 'recalc_request_cost', Router.current().params.doc_id
    #         $('.handler')
    #           .transition({
    #             animation : 'pulse'
    #             duration  : 500
    #             interval  : 200
    #           })
    #         $('.result')
    #           .transition({
    #             animation : 'pulse'
    #             duration  : 500
    #             interval  : 200
    #           })


    #     'click .cancel_request': ->
    #         if confirm 'delete request?'
    #             Docs.remove @_id
    #             Router.go "/rental/#{@rental_id}/"


    #     #     rental = Docs.findOne @rental_id
    #     #     # console.log @
    #     #     Docs.update @_id,
    #     #         $set:
    #     #             submitted:true
    #     #             submitted_timestamp:Date.now()
    #     #     Meteor.call 'pay_for_request', @_id, =>
    #     #         Router.go "/request/#{@_id}/"



if Meteor.isServer
    Meteor.methods
        recalc_request_cost: (res_id)->
            res = Docs.findOne res_id
            # console.log res
            rental = Docs.findOne res.rental_id
            hour_duration = moment(res.end_datetime).diff(moment(res.start_datetime),'hours',true)
            cost = parseFloat hour_duration*rental.hourly_dollars
            total_cost = cost
            taxes_payout = parseFloat((cost*.05))
            owner_payout = parseFloat((cost*.5))
            handler_payout = parseFloat((cost*.45))
            if rental.security_deposit_required
                total_cost += rental.security_deposit_amount
            if res.res_start_dropoff_selected
                total_cost += rental.res_start_dropoff_fee
                handler_payout += rental.res_start_dropoff_fee
            if res.res_end_pickup_selected
                total_cost += rental.res_end_pickup_fee
                handler_payout += rental.res_end_pickup_fee
            # console.log diff
            Docs.update res._id,
                $set:
                    hour_duration: hour_duration.toFixed(2)
                    cost: cost.toFixed(2)
                    total_cost: total_cost.toFixed(2)
                    taxes_payout: taxes_payout.toFixed(2)
                    owner_payout: owner_payout.toFixed(2)
                    handler_payout: handler_payout.toFixed(2)

        pay_for_request: (res_id)->
            res = Docs.findOne res_id
            # console.log res
            rental = Docs.findOne res.rental_id

            Meteor.call 'send_payment', Meteor.user().username, rental.owner_username, res.owner_payout, 'owner_payment', res_id
            Docs.insert
                model:'log_event'
                log_type: 'payment'

            Meteor.call 'send_payment', Meteor.user().username, rental.handler_username, res.handler_payout, 'handler_payment', res_id
            Meteor.call 'send_payment', Meteor.user().username, 'dev', res.taxes_payout, 'taxes_payment', res_id

            Docs.insert
                model:'log'
                parent_id:res_id
                res_id: res_id
                rental_id: res.rental_id
                log_type:'request_submission'
                text:"request submitted by #{Meteor.user().username}"

        send_payment: (from_username, to_username, amount, reason, request_id)->
            console.log 'sending payment from', from_username, 'to', to_username, 'for', amount, reason, request_id
            res = request_id
            sender = Docs.findOne username:from_username
            target = Docs.findOne username:to_username


            console.log 'sender', sender._id
            console.log 'target', target._id
            console.log typeof amount
            #
            amount  = parseFloat amount

            Docs.update sender._id,
                $inc: credit: -amount

            Docs.update target._id,
                $inc: credit: amount

            Docs.insert
                model:'transfer'
                sender_username: from_username
                sender_id: sender._id
                target_username: to_username
                target_user_id: target._id
                amount: amount
                request_id: request_id
                rental_id: res.rental_id
                reason:reason
            Docs.insert
                model:'log'
                log_type: 'payment'
                sender_username: from_username
                target_username: to_username
                amount: amount
                target_user_id: target._id
                text:"#{from_username} paid #{to_username} #{amount} for #{reason}."
                sender_id: sender._id
            return






if Meteor.isClient
    Router.route '/requests', (->
        @layout 'layout'
        @render 'requests'
        ), name:'requests'
    
    Template.requests.onCreated ->
        Session.setDefault 'view_mode', 'list'
        Session.setDefault 'sort_key', 'daily_rate'
        Session.setDefault 'sort_label', 'available'
        Session.setDefault 'limit', 20
        Session.setDefault 'view_open', true
        # @autorun => @subscribe 'count', ->
        @autorun => @subscribe 'model_docs','request',->
        @autorun => @subscribe 'facets',
            'request'
            picked_tags.array()
            Session.get('current_query')
            []
            picked_timestamp_tags.array()
            picked_location_tags.array()
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_request')
            Session.get('view_pickup')
            Session.get('view_open')

        @autorun => @subscribe 'results',
            'request'
            picked_tags.array()
            Session.get('current_query')
            picked_timestamp_tags.array()
            picked_location_tags.array()
            Session.get('limit')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('view_request')
            Session.get('view_pickup')
            Session.get('view_open')

    
    Template.requests.events
        'click .request_request': ->
            title = prompt "different title than #{Session.get('current_query')}"
            new_id = 
                Docs.insert 
                    model:'request'
                    title:Session.get('current_query')


        # 'click .toggle_request': -> Session.set('view_request', !Session.get('view_request'))
        # 'click .toggle_pickup': -> Session.set('view_pickup', !Session.get('view_pickup'))
        # 'click .toggle_open': -> Session.set('view_open', !Session.get('view_open'))

        'click .calc_request_count': ->
            Meteor.call 'calc_request_count', ->

    Template.requests.helpers
        counter: -> Counts.get('request_counter')
        tags: -> Results.find({model:'tag', title:$nin:picked_tags.array()})
        location_tags: -> Results.find({model:'location_tag',title:$nin:picked_location_tags.array()})
        authors: -> Results.find({model:'author'})

        result_class: ->
            if Template.instance().subscriptionsReady()
                ''
            else
                'disabled'



if Meteor.isServer 
    Meteor.publish 'request_results', (
        query=''
        picked_tags=[]
        picked_location_tags=[]
        limit=20
        sort_key='_timestamp'
        sort_direction=-1
        view_delivery
        view_pickup
        view_open
        )->
        console.log picked_tags
        self = @
        match = {}
        match.model = 'request'
        
        match.app = 'goldrun'
        # if view_open
        #     match.open = $ne:false
        # if view_delivery
        #     match.delivery = $ne:false
        # if view_pickup
        #     match.pickup = $ne:false
        # if Meteor.userId()
        #     if Meteor.user().downvoted_ids
        #         match._id = $nin:Meteor.user().downvoted_ids
        if query
            match.title = {$regex:"#{query}", $options: 'i'}
        
        if picked_tags.length > 0
            match.tags = $all: picked_tags
            # sort = 'price_per_serving'
        # if view_images
        #     match.is_image = $ne:false
        # if view_videos
        #     match.is_video = $ne:false
    
        # match.tags = $all: picked_tags
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array
    
        # console.log 'product match', match
        # console.log 'sort key', sort_key
        # console.log 'sort direction', sort_direction
        Docs.find match,
            sort:"#{sort_key}":sort_direction
            # sort:_timestamp:-1
            limit: limit

if Meteor.isClient
    Template.request_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'rental_from_request_id', Router.current().params.doc_id, ->
        # @autorun => Meteor.subscribe 'model_docs', 'dish'

    Template.request_edit.helpers
        # all_dishes: ->
        #     Docs.find
        #         model:'dish'
        can_delete: ->
            request = Docs.findOne Router.current().params.doc_id
            if request.request_ids
                if request.request_ids.length > 1
                    false
                else
                    true
            else
                true
        can_complete: ->
            request = Docs.findOne Router.current().params.doc_id
            request.amount < Meteor.user().points 
            
            # request.request_date
            
            
            
        points_after_purchase: ->
            user_points = Meteor.user().points
            current_request = Docs.findOne Router.current().params.doc_id
            Meteor.user().points - current_request.rental_daily_rate


    Template.request_edit.events
        'click .complete_request': (e,t)->
            Docs.update Router.current().params.doc_id,
                $set:
                    complete:true
                    completed_timestamp:Date.now()
                    
            $('body').toast(
                showIcon: 'checkmark'
                message: 'request completed'
                # showProgress: 'bottom'
                class: 'success'
                # displayTime: 'auto',
                position: "bottom right"
            )
            
            Router.go "/request/#{@_id}"


        'click .delete_request': (e,t)->
            if confirm 'cancel request?'
                doc_id = Router.current().params.doc_id
                $(e.currentTarget).closest('.grid').transition('fly right', 500)
                Router.go "/rental/#{@rental_id}"

                Docs.remove doc_id




if Meteor.isClient
    Template.profile_request_item.onCreated ->
        @autorun => Meteor.subscribe 'rental_from_request_id', @data._id
    Template.request_view.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'rental_from_request_id', Router.current().params.doc_id

    Template.request_view.onRendered ->
        Meteor.call 'log_doc_view', Router.current().params.doc_id, ->
            console.log 'logged doc view'
    Template.request_view.events
        'click .cancel_request': ->
            if confirm 'cancel?'
                Docs.remove @_id
                Router.go "/rental/#{@rental_id}"


    # Template.request_view.helpers
    #     can_request: ->
    #         # if StripeCheckout
    #         unless @_author_id is Meteor.userId()
    #             request_count =
    #                 Docs.find(
    #                     model:'request'
    #                     request_id:@_id
    #                 ).count()
    #             if request_count is @servings_amount
    #                 false
    #             else
    #                 true
    #         # else
    #         #     false




if Meteor.isServer
    Meteor.publish 'rental_from_request_id', (request_id)->
        request = Docs.findOne request_id
        Docs.find
            _id: request.rental_id

    Meteor.methods
        log_doc_view: (doc_id)->
            if doc = Docs.findOne doc_id
                Docs.update doc_id,
                    $inc:
                        views:1
                    $addToSet:
                        viewed_usernames:Meteor.user().username
                Docs.insert 
                    model:'log'
                    body:"#{@title} viewed by #{Meteor.user().username}"
    # Meteor.methods
        # request_request: (request_id)->
        #     request = Docs.findOne request_id
        #     Docs.insert
        #         model:'request'
        #         request_id: request._id
        #         request_price: request.price_per_serving
        #         buyer_id: Meteor.userId()
        #     Docs.update Meteor.userId(),
        #         $inc:credit:-request.price_per_serving
        #     Docs.update request._author_id,
        #         $inc:credit:request.price_per_serving
        #     Meteor.call 'calc_request_data', request_id, ->



if Meteor.isClient
    Template.user_requests.onCreated ->
        @autorun => Meteor.subscribe 'user_requests', Router.current().params.username
        # @autorun => Meteor.subscribe 'model_docs', 'rental'
    Template.user_requests.helpers
        requests: ->
            current_user = Docs.findOne username:Router.current().params.username
            Docs.find {
                model:'request'
            }, sort:_timestamp:-1

if Meteor.isServer
    Meteor.publish 'user_requests', (username)->
        user = Docs.findOne username:username
        if user
            Docs.find({
                model:'request'
                _author_id: user._id
            }, limit:20)
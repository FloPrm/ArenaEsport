class WalletsController < ApplicationController
  protect_from_forgery except: [:notification, :payment_response]
  skip_before_filter :verify_authenticity_token, only: [:notification, :payment_response]
  require 'net/http'
  require 'httparty'
  require 'base64'

  API_KEY = Base64.strict_encode64("psc_Foup-QJSLnk8stCyhTThYnP45z5knFq")

  def virtual_currency
    @wallet = current_user.wallet
  end

  def informations
    @wallet = current_user.wallet
  end

  def payment
    uri = URI('https://apitest.paysafecard.com/v1/payments')
    payment_request = Net::HTTP::Post.new(uri.path, 'Authorization' => "Basic #{API_KEY}", 'Content-Type' => 'application/json')
    payment_request.body = {
      type: "PAYSAFECARD",
      amount: params[:value].to_f.round(2),
      currency: "EUR",
      redirect: {
        success_url: payment_response_wallet_url(response:"success"),
        failure_url: payment_response_wallet_url(response:"failure")
      },
      notification_url: "http://hooks.arenaesport.ultrahook.com/wallets/notification",
      customer: {
        id: current_user.id.to_s
      }
    }.to_json

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = (uri.scheme == "https")
    response = http.request(payment_request)
    data = JSON.parse(response.body)
    id = data["id"]
    puts "\n\n #{data} \n\n"

    if !id.nil?
      WalletHistory.create(
        amount: params[:value].to_f.round(2),
        category:"paysafecard",
        action:"initiated",
        paysafecard: id,
        wallet: current_user.wallet
      )
      redirect_to data["redirect"]["auth_url"]
    else
      redirect_to informations_wallet_path, alert: "Une erreur s'est produite, impossible de se connecter à paysafecard. Veuillez contacter un administrateur."
    end
  end

  def notification
    put "\n\n NOTIFICATION REACHED \n\n"
    id = params[:mtid]
    puts "\n\n #{id} \n\n"
    @wallet_history = WalletHistory.find_by_paysafecard(id)
    @wallet = @wallet_history.wallet
    @gems = @wallet_history.amount.to_i * 150

    uri = URI('https://apitest.paysafecard.com/v1/payments/' + id)
    request = Net::HTTP::Get.new(uri.path, 'Authorization' => "Basic #{API_KEY}", 'Content-Type' => 'application/json')
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = (uri.scheme == "https")
    response = http.request(request)
    data = JSON.parse(response.body)
    puts "\n\n #{data} \n\n"

    if data["status"] == "AUTHORIZED"
      puts "\n\n NOTIFICATION CASE : AUTHORIZED \n\n"
      uri = URI('https://apitest.paysafecard.com/v1/payments/' + id + "/capture")
      request = Net::HTTP::Post.new(uri.path, 'Authorization' => "Basic #{API_KEY}", 'Content-Type' => 'application/json')
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      response = http.request(request)
      data = JSON.parse(response.body)
      puts "\n\n #{data} \n\n"

      if data["status"] == "SUCCESS"

        puts "\n\n NOTIFICATION CASE : SUCCESS \n\n"
        if @wallet_history.validation.nil?
          @wallet_history.validation = true
          @wallet_history.amount = @gems
          @wallet.balance += @gems
        end
      else
        @wallet_history.validation = false
      end # SUCCESS
      @wallet_history.action = data["status"].downcase
      @wallet_history.save!
      @wallet.save!
    end

    # Webhook::Received.save(data: data, paysafecard: params[:paysafecard])
    render nothing: true
  end

  def payment_response
    Wallet.transaction do
      @wallet = Wallet.find(params[:id])
      if params[:response] == "success"
        @wallet_history = @wallet.wallet_histories.where.not(paysafecard:nil).last
        @gems = @wallet_history.amount * 150

        uri = URI('https://apitest.paysafecard.com/v1/payments/' + @wallet_history.paysafecard)
        request = Net::HTTP::Get.new(uri.path, 'Authorization' => "Basic #{API_KEY}", 'Content-Type' => 'application/json')
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = (uri.scheme == "https")
        response = http.request(request)
        data = JSON.parse(response.body)
        puts "\n\n #{data} \n\n"

        if data["status"] == "AUTHORIZED"

          puts "\n\n PAYMENT REPONSE CASE : AUTHORIZED \n\n"
          uri = URI('https://apitest.paysafecard.com/v1/payments/' + @wallet_history.paysafecard + "/capture")
          request = Net::HTTP::Post.new(uri.path, 'Authorization' => "Basic #{API_KEY}", 'Content-Type' => 'application/json')
          http = Net::HTTP.new(uri.hostname, uri.port)
          http.use_ssl = (uri.scheme == "https")
          response = http.request(request)
          data = JSON.parse(response.body)
          puts "\n\n #{data} \n\n"

          if data["status"] == "SUCCESS"

            puts "\n\n NOTIFICATION CASE : SUCCESS \n\n"
            if @wallet_history.validation.nil?
              @wallet_history.validation = true
              @wallet_history.amount = @gems
              @wallet.balance += @gems
            end
          else
            @wallet_history.validation = false
          end # SUCCESS
          @wallet_history.action = data["status"].downcase
          @wallet_history.save!
          @wallet.save!
          redirect_to payment_result_wallet_path(@wallet)
        end # AUTHORIZED
      else
        redirect_to payment_result_wallet_path(@wallet)
      end # success
    end # transaction
  end

  def payment_result
    @wallet = Wallet.find(params[:id])
    @wallet_history = @wallet.wallet_histories.where.not(paysafecard:nil).last
    @gems = @wallet_history.amount
  end

end

class QuotesController < ApplicationController
  before_action :logged_in_user

  # This method is for testing exception notifier:
  def boom
    raise 'NopeNopeNope'
  end

  def index
    @new_quote = Quote.new
    @display_quotes = current_user.setting.display_quotes
  end

  def show
    @quote = current_user.quotes.find_by_id(params[:id])
    if @quote.nil?
      flash[:danger] = 'Show quote failed: quote not found'
      redirect_to(quotes_path) && return
    end

    respond_to do |f|
      f.js
    end
  end

  def create
    @new_quote = current_user.quotes.build(quote_params)
    if @new_quote.save
      flash[:success] = 'New quote created'
      redirect_to(quotes_path)
    else
      @display_quotes = current_user.setting.display_quotes
      @quotes = current_user.quotes.reload
      render('index')
    end
  end

  def edit
    @quote = current_user.quotes.find_by_id(params[:id])
    if @quote.nil?
      flash[:danger] = 'Quote not found'
      redirect_to(quote_path) && return
    end

    respond_to do |f|
      f.js
    end
  end

  def update
    @quote = current_user.quotes.find_by_id(params[:id])
    if @quote.nil?
      flash[:danger] = 'Updating quote failed: quote not found'
      redirect_to(quotes_path) && return
    end

    flash[:success] = 'Quote updated' if @quote.update(quote_params)
    redirect_to(quotes_path)
  end

  def destroy
    @quote = current_user.quotes.find_by_id(params[:id])
    if @quote.nil?
      flash[:danger] = 'Deleting quote failed: quote not found'
      redirect_to(quotes_path) && return
    end

    @quote.destroy!
    flash[:success] = 'Quote deleted'
    redirect_to(quotes_path)
  end

  private

  def quote_params
    params.require(:quote).permit(:quotation, :source)
  end
end

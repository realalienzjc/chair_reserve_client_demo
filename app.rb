#encoding: UTF-8
require 'sinatra'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/contrib/all'

require 'date'


class SeatService

    attr_reader :start_timestamp, :stop_timestamp, :seat_num, :is_sofa, :discount_ratio
    attr_accessor :phone

    def initialize(phone)
        @phone = phone
        @start_timestamp = DateTime.now
        @stop_timestamp = nil
        @seat_num = rand(100)
        @is_sofa = ( @seat_num <=50 )
    end

    def elapsed

        diff = (@stop_timestamp.nil? ? DateTime.now : @stop_timestamp ) - @start_timestamp 


        time_str = ""
        # hr
        hr = (diff *30 * 24).to_i
        time_str += "#{hr}小时" if hr > 0
        # min
        min = (diff *30 * 24*60).to_i % 60
        time_str += "#{min}分钟"

        time_str
    end

    def get_discount_info
        discount = "没有优惠"
        time_str = self.elapsed
        if time_str =~ /小时/
            discount  = "抱歉：由于超过1个小时，无法享受这刻。"
        else
            discount  = "恭喜：您的消费为9折。"
        end
    end

    def mark_as_done
        @stop_timestamp = DateTime.now
    end

    def is_over?
        @stop_timestamp != nil
    end

    def reset
        @start_timestamp = DateTime.now
        @stop_timestamp = nil
        @seat_num = rand(100)
        @is_sofa = ( @seat_num <=50 )
    end

end


class MyApp < Sinatra::Base
    
    enable :sessions
    register Sinatra::Flash
    register Sinatra::Contrib
    helpers Sinatra::Cookies
    

    get '/' do
        #redirect '/new'
        
        # Barcode scan test
        # NOTE: barcode should point to the page that
        #  * explain the activity hosted by the restaurant and
        #  * allow user to confirm the participation, acknowledging the rules.
        redirect '/new'
    end

    get '/new' do
        erb :new
    end

    post '/create' do
        phone = params[:phone]
        puts phone

        if phone.empty? || phone.length != 11
            flash[:message] = "手机号码为空，或不正确，请重新输入11位手机号！"
            redirect '/new'
        else
            @game = SeatService.new(phone)
            session[:game] = @game
            redirect '/show'
        end        
    end


    get '/show' do
        ### YOUR CODE HERE ###
        # status = @game.check_if_over
        # redirect '/win' if status == :win
        # redirect '/lose' if status == :lose
        if session[:game]
            puts "[Info] found :game in the session"
            @game = session[:game]
            erb :show # You may change/remove this line
        else 
            puts "[Error] not finding :game in the session, please check!"
            redirect '/new'
        end
    end

    post '/desk_call' do
        if params[:call] == '点菜'
            flash[:message] = "服务员马上就来，请您稍等片刻！"
        elsif params[:call] == '额外餐具'
            flash[:message] = "餐具这就送来！"
        elsif params[:call] == '白开水'
            flash[:message] = "马上给您倒水！"
        elsif params[:call] == '买单！'
            flash[:message] = "服务员为您打印结账单，请稍候！"
            redirect '/checkout'
            return
        elsif params[:call] == '参与抽奖！'
            flash[:message] = "如果已结账完成离座，请在商户门口扫描抽奖二维码！欢迎您下次再来！"
        elsif params[:call] == '重新开始'
            @game = session[:game]
            @game.reset
            redirect '/new'
        end

        redirect '/show'
    end

    get '/checkout' do
        erb :checkout
    end

    post '/checkout' do
        # TODO: 检查
        if params[:cost]
            @game = session[:game]
            @game.mark_as_done
            flash[:message] = @game.get_discount_info
            redirect '/show'
        else
            redirect '/checkout'
        end
    end


end



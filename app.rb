require "sinatra/base"
require "sinatra/reloader"


class App < Sinatra::Base

    enable :sessions

    get '/' do
        @ueue = Queue::restore(session)
        @queue = Queue::new(Person::PEOPLE, nil) 

        quiz = Person.quiz(@queue)

        $correct = quiz[:correct]
        @alternatives = quiz[:alternatives]       

        erb :index
    end

    get '/svar' do
        @correct = $correct

        erb :svar
    end

    post '/guess' do
        answer = params["test"]

        if answer == $correct[1]
            session["response"] = "Rätt"
        else
            session["response"] = "Fel"
        end
        redirect('/svar')

    end
end
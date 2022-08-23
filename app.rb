# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/reloader'

##
# Huvudklassen
class App < Sinatra::Base
  enable :sessions

  get '/' do
    random = (PEOPLE_ARRAY[rand(0..(PEOPLE_ARRAY.length - 1))])
    @random = Person.new(random[:id], random[:name])

    erb :index
  end

  get '/quiz' do
    redirect '/' if session[:settings].nil?

    @quiz = Quiz.restore(session)

    if @quiz.nil?
      people = session[:settings][:names].split("\n").map { |name| Person.new(name) }
      @quiz = Quiz.new(Queue.new(people, nil))
    end

    p @quiz

    session['response'] = -1

    turn = @quiz.create_turn(session[:settings])

    session[:correct] = turn[:correct]
    @alternatives = turn[:alternatives]

    @quiz.save(session)

    erb :quiz
  end

  post '/guess' do
    answer = params['test']
    return redirect('/') unless session && session[:correct]

    quiz = Quiz.restore(session)
    is_correct = quiz.answer(answer)

    quiz.save(session)
    session['response'] = is_correct ? 'Rätt' : 'Fel'

    redirect('/resultat') if quiz.done?

    redirect('/svar')
  end

  get '/svar' do
    @correct = session[:correct]
    redirect '/quiz' if @correct.nil?
    erb :svar
  end

  post '/setup' do
    settings = params
    session[:settings] = settings

    redirect('/quiz')
  end

  get '/resultat' do
    quiz = Quiz.restore(session)
    redirect '/' if quiz.nil?

    history = quiz.history.history
    face = history.max_by { |faces| history.count(faces) }[0]
    name = history.max_by { |names| history.count(names) }[1]

    @worst_face = quiz.queue.initial.find { |person| person.id == face }
    @worst_name = quiz.queue.initial.find { |person| person.name == name }

    @correct = history.select { |result| result[2] }
    @incorrect = history.reject { |result| result[2] }

    erb :resultat
  end

  post '/reset' do
    session[:quiz] = nil

    redirect('/')
  end

  get '/timeout' do
    answer = 'Out of Time'
    quiz = Quiz.restore(session)
    is_correct = quiz.answer(answer)
    quiz.save(session)

    p 'out of luck'

    session['response'] = 'Fel'
    redirect('/svar')
  end
end

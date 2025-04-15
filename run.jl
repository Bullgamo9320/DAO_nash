include("sample_games.jl")

############ Logger LEVEL設定（デフォルトはINFO） ############
#debuglogger = Logging.ConsoleLogger(stderr, Logging.Debug)
#Logging.global_logger(debuglogger)

############ サンプルゲームの実行 ############
#@time DAO_find_nash_equilibrium(n)
#@time DAO_game2(n)
@time DAO_game3(n) 
#@time DAO_sand(n)
#@time prisoners_dilemma1()
#@time prisoners_dilemma2()
#@time prisoners_dilemma3()
#@time battle_of_sex()
#@time cournot_game1()#
#@time cournot_game2()
#@time textbook_ex33a()
#@time hawk_dove_game()


module GameResolver
using ProgressBars
export AbstractPlayer, Player, SimplifiedPlayer, Game, get_Nash_equilibrium, get_Nash_equilibrium_idx, transform_to_payoff_matrix, strategy_profile


#####################################################
###### Type alias #######################################
#####################################################
"""
プレイヤの持つアクションの型をエイリアスとして設定
StringのリストかFloat64のリストとして設定
"""
const Action = Union{Vector{String},Vector{Float64}}


#####################################################
###### Struct #######################################
#####################################################
abstract type AbstractPlayer end

struct SimplifiedPlayer <: AbstractPlayer
    id::Int64 #プレイヤのindexを表す。重複しないこと。
    payoff_matrix::Array{Float64}
end

struct Player <: AbstractPlayer
    id::Int64 #プレイヤのindexを表す。重複しないこと。
    actions::Action
    payoff_func::Function #自分の行動を1つ目の引数に、他のプレイヤの行動のリストを第２引数にとる関数として定義すること（e.g f(s_1, s_{-i})）
end

struct Game
    players::Vector{AbstractPlayer}
end


#####################################################
###### Function #####################################
#####################################################
"""
    strategy_profiles(actions1,actions2) -> Channel{Action}

すべてのプレイヤのAction (行動のリスト) を引数として、その直積集合のcollectionを生成する　
Generates the collection of the CartesianProduct created from all player's actions as arguments

the arguments of actions1, actions2, ...

# Arguments:
* action::Action: The list of actions that a plyer has
"""
function strategy_profiles(action::Action...)::Channel{Action}
    #各プレイヤが持つ行動の数をリストにしたもの
    size_of_each_action::Vector{Int} = [length(i) for i in action]

    #PythonのGenerator的にChannelを使う
    Channel{Action}() do channel
        for indices in CartesianIndices(tuple(size_of_each_action...))
            list = [action[i][indices[i]] for i in 1:length(indices)] #eachindexが使えない
            put!(channel, list)
        end
    end
end

"""
CartesianIndexから対応する戦略プロファイル（Vector{String} or Vector{Float64}）を返す。
"""
function strategy_profile(idx::CartesianIndex, actions::Action...)::Action
    # CartesianIndex から戦略プロファイルを返す
    #あとで作る
    return [action[idx[i]] for (i, action) in enumerate(actions)]
end


"""
strategy_profileがナッシュ均衡であれば、trueを返す。ナッシュ均衡でなければ、falseを返す。
"""
function nash_check(strategy_profile::Action, players::Player...)::Bool
    for player in players
        i = player.id
        my_action = strategy_profile[i]
        other_strategy_profile = deleteat!(copy(strategy_profile), i)

        #引数で与えられた戦略プロファイルにおける利得の値を代入
        payoff_value = player.payoff_func(my_action, other_strategy_profile...)

        #上記の利得を上回る戦略があればfalseを返してループを中断
        for action in player.actions
            if payoff_value < player.payoff_func(action, other_strategy_profile...)
                return false
            end
        end
    end
    #全てのプレイヤーについて、payoff_value の方が高ければNash均衡となっている
    return true
end

"""
引数のgameからナッシュ均衡を計算し、リストとして返す。
"""
function get_Nash_equilibrium(game::Game)::Vector{Action}
    nash_list::Vector{Action} = []
    actions_list = [p.actions for p in game.players]

    total_repetition = reduce(*, [length(i) for i in actions_list])
    p_bar = ProgressBar(total=total_repetition)
    for strategy_profile in strategy_profiles(actions_list...)
        if nash_check(strategy_profile, game.players...)
            push!(nash_list, strategy_profile)
        end
        update(p_bar)
    end
    return nash_list
end


############ 以下からMatrixバージョン ######################
"""
    best_response_check(payoff_matrix, profile_idx) -> Bool

Check if the strategy profile is a best reponse or not on a player basis

# Arguments
* `payoff_matrix::Array{Float16}`: The target player's payoff matrix
* `idx::CartesianIndex`: the Cartesian index of the payoff matrix corresponding to a certain strategy profile to be checked
"""
function best_response_check(payoff_matrix::Array{Float64}, profile_idx::CartesianIndex)::Bool
    current_payoff = payoff_matrix[profile_idx]
    reduced_idx = CartesianIndex(Tuple(profile_idx)[2:end]) #最初のプレイヤを除いたidx
    payoff_vector = payoff_matrix[:, reduced_idx] #他のプレイヤの行動を固定した時の、Player1の取りうる利得を格納したVector

    for payoff in payoff_vector
        if current_payoff < payoff
            return false
        end
    end
    return true #current_payoffが最も高ければ、そればBest Reponse
end


"""
    get_Nash_equilibrium_idx(game) -> Array{CartesianIndex}

Obtain the Nash equilibrium list. Please note that the list has the CartesianIndex values, each of which corresponds to a strartegy profile of Nash equilibria in the game.

# Arguments
* `game::Game`: The struct named Game
"""
function get_Nash_equilibrium_idx(game::Game)::Vector{CartesianIndex}
    nash_list::Vector{CartesianIndex} = []
    p1_payoff_matrix = game.players[1].payoff_matrix #代表でPlayer1のものを代入

    for profile_idx in ProgressBar(CartesianIndices(p1_payoff_matrix))
        br_flg = true
        for player in game.players
            i = player.id #PlayerのIDがそのままindexになるように対応をとっておくこと！
            value_at_i = profile_idx[i]
            reduce_profile_idx = CartesianIndex(Tuple(deleteat!(collect(Tuple(profile_idx)), i)))
            arranged_profile_idx = CartesianIndex(value_at_i, reduce_profile_idx)

            if !best_response_check(player.payoff_matrix, arranged_profile_idx)
                br_flg = false
                break
            end
        end
        if br_flg
            push!(nash_list, profile_idx)
        end
    end
    nash_list
end

"""
利得関数からmatrix形式へ変換する。
"""
function transform_to_payoff_matrix(payoff_function::Function, my_actions::Action, others_actions::Action...)::Array{Float64}
    #Payoff matrixの次元を取得
    dim = Tuple(Iterators.flatten([length(my_actions), [length(i) for i in others_actions]]))

    # 0で初期化
    payoff_matrix = zeros(dim)

    # payoff matrix を生成
    for idx in ProgressBar(CartesianIndices(dim))
        action_list = [my_actions[idx[1]]]
        temp_others_actions = [actions[idx[i+1]] for (i, actions) in enumerate(others_actions)]

        #繋げて1つの strategy profile に
        append!(action_list, temp_others_actions)
        payoff_matrix[idx] = payoff_function(action_list...)
    end
    payoff_matrix
end

end # End of module

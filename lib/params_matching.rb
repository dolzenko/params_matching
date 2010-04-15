# ParamsMatching
# --------------
#
# Provides a simple way to extract values from the request `params` hash in your controllers.
#
# Supports multiple value extraction, nested values extraction, default values,
# yielding extracted values to the passed block.
#
# Usage
# -----
#
#     class ApplicationController < ActionController::Base
#       include ParamsMatching
#
# This will overwrite `params` accessor so that you can
#
# * extract multiple params at once
#
#          User.authenticate(*params(:login, :password))   # instead of User.authenticate(params[:login], params[:password])
#
# * safely extract nested params
#
#          name = params(:user => :name)   # instead of name = params[:user] && params[:user][:name]
#
# * specify default value for the param (currently only `[]` and `{}` are supported)
#
#          params(user_ids => []).each do |user_id|    # instead of (params[:user_ids] || []).each do |user_id|
#
# * use extracted params by passing block.
#   `params()` will yield to block only when *all* extracted params *are not nil*.
#
#          params(:user_id) do |user_id|   # instead of
#                                          #   if params[:user_id]
#                                          #     user_id = params[:user_id]
#
#   This behavior could seem inconsistent with what `params()` returns when used without
#   the block, but it's usually what you want and the purpose is kind of twofold.
#
#   It lets you encapsulate some optional logic which should be triggered
#   only when some param is present:
#
#             params(:hide_activated) { @users.reject!(&:activated?) }    # instead of
#                                                                         #   if params[:hide_activated]
#                                                                         #     @users.reject!(&:activated_at)
#                                                                         #   end
#
#   Since all extracted values must not be nil this could also serve as
#   the sanity checking tool:
#
#             params(:bookmark => [ :target_type, :target_id ]) do |target_type, target_id|
#               Bookmark.create!(:target => target_type.constantize.find(target_id))
#             end
#             # instead of
#             #   if params[:bookmark] &&
#             #       params[:bookmark][:target_type] &&
#             #       params[:bookmark][:target_id]
#             #     Bookmark.create!(:target => params[:target_type].constantize.find(params[:target_id]))
#             #   end
#
# Then of course these features could be mixed in a variety of ways
#
# Examples
# --------
#
# Change user password only when `params[:old_password]`, `params[:user][:password]`,
# and `params[:user][:password_confirmation]` are `present?`.
# Don't fail with "undefined method \`[]' for nil:NilClass" exception when
# `params[:user]` is nil.
#
#     if params(:old_password, :user => [ :password, :password_confirmation]).all?(&:present?)
#       # change password here
#     end
#
# Now to some extra byte squeezing, say you want to set @user instance variable only
# when `params[:user_id]` is passed, usually it's done like this
#
#     @user = params[:id] && User.find(params[:id])
#
# With ParamsMatching you can save 4 keystrokes and remove repeated `params[:id]`
# incantation
#
#     @user = params(:id, &User.method(:find))
#



module ParamsMatching
  protected

  def params(*args)
    return super() if args.empty?
    matched = ParamsMatching.match(super(), args)
    if block_given?
      if matched.all?
        matched.size == 1 ? yield(matched.first) : yield(*matched)
      end
    else
      matched.size == 1 ? matched.first : matched
    end
  end

  def self.match(params, query, match_container = nil)
    match_container ||= []

    case query
      when String, Symbol
        # terminator
        match_container << params[query]
      when Hash
        query.keys.map do |param_name|
          # handle default empty Array or Hash
          if ParamsMatching.suitable_default_value?(query[param_name])
            if params[param_name].nil?
              # add default since param is nil
              match_container << query[param_name]
            else
              # add present value
              match_container << params[param_name]
            end
          else
            # recurse with default empty Hash to be able to drill down to arbitrary level
            ParamsMatching.match(params[param_name] || {}, query[param_name], match_container)
          end
        end
      when Array
        query.map do |param_name|
          ParamsMatching.match(params, param_name, match_container)
        end
    end

    match_container
  end

  def self.suitable_default_value?(value)
    [ [], {} ].include?(value)
  end
end
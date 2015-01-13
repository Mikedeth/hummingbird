class GroupMembersController < ApplicationController
  before_action :authenticate_user!

  def create
    membership_hash = params.require(:group_member).permit(:group_id, :user_id).to_h

    return error! "Wrong user", 403 if current_user.id != membership_hash['user_id'].to_i
    return error! "Already in group", :conflict if GroupMember.exists?(membership_hash.slice('user_id', 'group_id'))

    membership = GroupMember.create!(membership_hash)
    render json: membership, status: :created
  end

  def update
    if current_member.admin?
      membership_hash = params.require(:group_member).permit(:rank, :pending).to_h
    elsif current_member.mod?
      membership_hash = params.require(:group_member).permit(:pending).to_h
    else
      return error! "Only admins and mods can do that", 403
    end

    membership.attributes = membership_hash

    # If they were an admin and their rank is being changed, check that they're not the last admin
    if membership.rank_changed? && membership.rank_was == 'admin' && !group.can_admin_resign?
      return error! "Last admin cannot resign", 400
    else
      membership.save!
      render json: membership
    end
  end

  def destroy
    return error! "Last admin cannot leave group", 400 if membership.admin? && !group.can_admin_resign?
    return error! "Mods can only boot plebs", 403 if current_member.mod? && current_user.id != membership.user_id && !membership.pleb?
    return error! "Wrong user", 403 if current_member.pleb? && current_user.id != membership.user_id

    membership.destroy
    render json: {}
  end


  private
  def current_member
    group.member(current_user)
  end

  def group
    membership.group
  end

  def membership
    GroupMember.find(params[:id])
  end
end

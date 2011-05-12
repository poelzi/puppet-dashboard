Factory.define :node_group do |group|
  group.name { Factory.next(:name) }
end

Factory.define :node_class do |node_class|
  node_class.name { Factory.next(:name) }
end

Factory.define :parameter do |parameter|
  parameter.sequence(:key)   {|n| "Key #{n}"   }
  parameter.sequence(:value) {|n| "Value #{n}" }
end

Factory.define :report do |report|
  report.status "failed"
  report.kind   "apply"
  report.host do |rep|
    if rep.node 
      rep.node.name 
    else
      Factory.next(:name)
    end
  end
  report.time   { Factory.next(:time) }
end

Factory.define :failing_report, :parent => :report do |report|
  report.status 'failed'
end

Factory.define :inspect_report, :parent => :report do |inspect|
  inspect.kind 'inspect'
end

Factory.define :resource_status do |status|
end

Factory.define :resource_event do |event|
end

Factory.define :node do |node|
  node.name { Factory.next(:name) }
end

Factory.define :reported_node, :parent => :node do |node|
  node.after_create do |node|
    Report.generate!(:host => node.name)
    node.reload
  end
end

Factory.define :unresponsive_node, :parent => :reported_node do |node|
  node.after_create do |node|
    node.last_apply_report.update_attributes!(:time => 2.days.ago)
    node.update_attributes!(:reported_at => 2.days.ago)
  end
end

Factory.define :current_node, :parent => :reported_node do |node|
  node.after_create do |node|
    node.last_apply_report.update_attributes!(:time => 2.minutes.ago)
    node.update_attributes!(:reported_at => 2.minutes.ago)
  end
end

Factory.define :failing_node, :parent => :current_node do |node|
  node.after_create do |node|
    node.last_apply_report.update_attributes!(:status => 'failed')
    node.update_attributes!(:status => 'failed')
  end
end

Factory.define :successful_node, :parent => :current_node do |node|
  node.after_create do |node|
    node.last_apply_report.update_attributes!(:status => 'changed')
    node.update_attributes!(:status => 'changed')
  end
end

Factory.define :pending_node, :parent => :successful_node do |node|
  node.after_create do |node|
    node.last_apply_report.resource_statuses.generate().events.generate(:status => 'noop')
  end
end

Factory.define :compliant_node, :parent => :successful_node do |node|
  node.after_create do |node|
    node.last_apply_report.resource_statuses.generate().events.generate(:status => 'success')
  end
end

Factory.sequence :name do |n|
  "name_#{n}"
end

Factory.sequence :time do |n|
  # each things created will be 1 hour newer than the last
  # might be a problem if creating more than 1000 objects
  (1000 - n).hours.ago
end

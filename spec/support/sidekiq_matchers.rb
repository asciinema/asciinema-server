RSpec::Matchers.define :have_queued_job do |*expected|
  match do |actual|
    actual.jobs.any? { |job| Array(expected) == job["args"] }
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have a job queued with #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not a have a job queued with #{expected}"
  end

  description do
    "have a job queued with #{expected}"
  end
end

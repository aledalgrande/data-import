require 'unit/spec_helper'

describe DataImport::PartialMigration do

  let(:mock_progress_class) do
    Class.new do
      def initialize(name, total_steps); end

      def finish; end
    end
  end

  context 'with simple definitions' do
    let(:people) { DataImport::Definition.new('People', 'tblPerson', 'people', nil) }
    let(:animals) { DataImport::Definition.new('Animals', 'tblAnimal', 'animals', nil) }
    let(:articles) { DataImport::Definition.new('Articles', 'tblNewsMessage', 'articles', nil) }
    let(:plan) { DataImport::ExecutionPlan.new }
    before do
      plan.add_definition(articles)
      plan.add_definition(people)
      plan.add_definition(animals)

      File.delete('.import_definitions') if File.exist?('.import_definitions')
      File.delete('.import_mappings') if File.exist?('.import_mappings')
    end

    it 'runs a set of definitions' do
      subject = described_class.new(plan, {}, mock_progress_class)

      articles.should_receive(:run)
      people.should_receive(:run)
      animals.should_receive(:run)

      subject.run
    end

    it ":only limits the definitions, which will be run" do
      subject = described_class.new(plan, {:only => ['People', 'Articles']}, mock_progress_class)

      people.should_receive(:run)
      articles.should_receive(:run)

      subject.run
    end
  end

  context 'with already run definitions' do
    let(:animals) { DataImport::Definition.new('Animals', 'tblAnimal', 'animals', nil) }
    let(:articles) { DataImport::Definition.new('Articles', 'tblNewsMessage', 'articles', nil) }
    let(:plan) { DataImport::ExecutionPlan.new }

    before do
      plan.add_definition(articles)
      plan.add_definition(animals)

      File.open('.import_definitions', 'w') do |f|
        f << Marshal.dump(['Animals'])
      end
      File.delete('.import_mappings') if File.exist?('.import_mappings')
    end

    subject { described_class.new(plan, {}, mock_progress_class) }

    it 'skips already run definitions' do
      articles.should_receive(:run)
      animals.should_not_receive(:run)

      subject.run
    end
  end
end
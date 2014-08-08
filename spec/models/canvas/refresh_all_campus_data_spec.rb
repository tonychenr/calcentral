require "spec_helper"

describe Canvas::RefreshAllCampusData do
  subject { Canvas::RefreshAllCampusData.new('incremental') }

  before do
    Canvas::Proxy.stub(:current_sis_term_ids).and_return(current_sis_term_ids)
    frozen_moment_in_time = Time.at(1388563200).to_datetime
    DateTime.stub(:now).and_return(frozen_moment_in_time)
  end

  context 'with multiple terms' do
    let(:current_sis_term_ids) { ["TERM:2013-D", "TERM:2014-B"] }
    it "establishes the csv import files" do
      expect(subject.users_csv_filename).to be_an_instance_of String
      expect(subject.users_csv_filename).to eq "tmp/canvas/canvas-2014-01-01-users-incremental.csv"
      expect(subject.term_to_memberships_csv_filename).to be_an_instance_of Hash
      expect(subject.term_to_memberships_csv_filename['TERM:2013-D']).to eq "tmp/canvas/canvas-2014-01-01-TERM_2013-D-enrollments-incremental.csv"
      expect(subject.term_to_memberships_csv_filename['TERM:2014-B']).to eq "tmp/canvas/canvas-2014-01-01-TERM_2014-B-enrollments-incremental.csv"
    end
    it "makes calls to each step of refresh in proper order" do
      subject.should_receive(:make_csv_files).ordered.and_return(true)
      subject.should_receive(:import_csv_files).ordered.and_return(true)
      subject.run
    end
    it "should send call to populate incremental update csv for users and enrollments" do
      Canvas::MaintainUsers.any_instance.should_receive(:refresh_existing_user_accounts).once.and_return(nil)
      expect_any_instance_of(Canvas::RefreshAllCampusData).to receive(:refresh_existing_term_sections).twice.and_return(nil)
      subject.make_csv_files
    end
  end

  describe 'term-specific work' do
    let(:current_sis_term_ids) { ["TERM:2014-B"] }
    let(:ccn) { "#{random_id}" }
    let(:canvas_term_sections_csv_string) do
      [
        'canvas_section_id,section_id,canvas_course_id,course_id,name,status,start_date,end_date,canvas_account_id,account_id',
        "#{ccn}2,SEC:2014-B-2#{ccn},#{random_id},CRS:#{ccn},DIS 101,active,,,105300,ACCT:LAW",
        "#{random_id},,#{random_id},CRS:#{ccn},INFORMAL 2,active,,,105300,ACCT:EDUC",
        "#{random_id},SEC:2014-B-#{random_id},#{random_id},,LAB 201,active,,,105300,ACCT:EDUC",
        "#{ccn}1,SEC:2014-B-1#{ccn},#{random_id},CRS:#{ccn},DIS 102,active,,,105300,ACCT:LAW"
      ].join("\n")
    end
    let(:canvas_term_sections_csv_table) { CSV.parse(canvas_term_sections_csv_string, {headers: true}) }
    before do
      allow_any_instance_of(Canvas::MaintainUsers).to receive(:refresh_existing_user_accounts)
      allow_any_instance_of(Canvas::SectionsReport).to receive(:get_csv).and_return(canvas_term_sections_csv_table)
    end
    it 'passes well constructed parameters to the memberships maintainer' do
      expect(Canvas::SiteMembershipsMaintainer).to receive(:new) do |course_id, csv_rows, enrollments_csv, users_csv, known_users, batch_mode|
        expect(course_id).to eq "CRS:#{ccn}"
        expect(csv_rows.size).to eq 2
        expect(csv_rows[0]['section_id']).to eq "SEC:2014-B-2#{ccn}"
        expect(csv_rows[1]['section_id']).to eq "SEC:2014-B-1#{ccn}"
        expect(known_users).to eq []
        expect(batch_mode).to be_false
        double(refresh_sections_in_course: nil)
      end
      subject.make_csv_files
    end

  end

end

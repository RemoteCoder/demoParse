class UserDetailsController < ApplicationController
  def index
    @user_details = UserDetail.order("field_valid_status ASC")
    respond_to do |format|
      format.html
      format.json
    end
  end

  def import_csv_or_xlsx
    @us_states_downcase = hash_downcase_key(us_states)
    spreadsheet = open_spreadsheet(params[:file])
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      # row = Hash[[header, spreadsheet.row(i)].transpose]
      row = spreadsheet.row(i)
      result_hash = process_row_data(header, row)
      UserDetail.create(result_hash)

    end

    redirect_to root_url, notice: "Products imported."
  end


  # def import_csv_or_excel
  #
  # end

  def process_row_data(header, row)
    temp = {}
    temp["note"] =''
    temp['field_valid_status'] = true

    # First Name

    fn_status, temp['first_name'] = valid_name(row[0])
    unless fn_status
      temp["note"] += "First Name is Blank /Invalid : #{row[0]}<br>"
      temp['field_valid_status'] = false
    end

    #Second Name

    ln_status, temp['last_name'] = valid_name(row[1])
    unless ln_status
      temp["note"] += "Second Name is Blank / Invalid : #{row[1]}<br>"
      temp['field_valid_status'] = false
    end

    #Email
    email_status, temp['email'] = valid_email(row[2])
    unless email_status
      temp["note"] += "Invalid Email : #{row[2]} \<br>"
      temp['field_valid_status'] = false
    end

    #Phone
    phone_status, temp['phone'] = valid_phone(row[3])
    unless phone_status
      temp["note"] += "Invalid Phone : #{row[3]} \<br>"
      temp['field_valid_status'] = false
    end
    # Street
    street_status, temp['street'] = valid_street(row[4])
    unless street_status
      temp["note"] += "Invalid Street :  #{row[4]} \<br>"
      temp['field_valid_status'] = false
    end

    #City
    city_status, temp['city'] = valid_city(row[5])
    unless city_status
      temp["note"] += "Invalid City : #{row[5]} </br>"
      temp['field_valid_status'] = false
    end

    #State -- PENDING
    state_status, temp['state'] = valid_state(row[6])
    unless state_status
      temp["note"] += "Invalid State : #{row[6]} </br>"
      temp['field_valid_status'] = false
    end

    #zipCode
    zip_status, temp['zip_code'] = valid_zip_code(row[7])
    unless zip_status
      temp["note"] += "Invalid Zip Code : #{row[7]} </br>"
      temp['field_valid_status'] = false
    end

    # Job Service
    job_status, temp['job_service_name'] = valid_job_service(row[8])
    unless job_status
      temp["note"] += "Job Service is Blank/Invalid : #{row[8]} </br>"
      temp['field_valid_status'] = false
    end

    # Price price (float and not negative)
    price_status, temp['price'] = price_validation(row[9])
    unless price_status
      temp["note"] += "Invalid Price : #{row[9]} </br>"
      temp['field_valid_status'] = false
    end


    #Cycle cycle in (days) integer
    cycle_status, temp['cycle'] = cycle_validation(row[10])
    unless cycle_status
      temp["note"] += "Invalid Cycle : #{row[10]} </br>"
      temp['field_valid_status'] = false
    end

    # NextJobDate
    job_date_status, temp['next_job_at'] = valid_next_job_date(row[11])
    unless job_date_status
      temp["note"] += "Invalid Next Job date : #{row[11]} </br>"
      temp['field_valid_status'] = false
    end
    temp


  end


  def valid_name(name)
    name = name.to_s.gsub!(/\W|_|[0-9]/, '') if name.to_s =~ /\W|_|[0-9]/
    return [false, name.to_s] unless name.to_s.length > 0
    [true, name.titleize]
  end

  def valid_email(email)
    return [false, email] unless email =~ /\A(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})\z/i
    [true, email]
  end

  def valid_phone(phone)
    phone.to_s.gsub!(/\W|_|[a-z]/, '') if phone..to_s =~ /\W|_|[a-z]/
    return [false, phone.to_i.to_s] unless phone.to_i.to_s.length == 10
    [true, phone.to_i.to_s]

  end

  def valid_street(street)
    return [false, street] unless street =~ /\A\d+/
    [true, street]
  end

  def valid_city(city)
    return [false, city] unless city =~ /\A[A-Za-z]+\z/
    [true, city]
  end

  def valid_state(state)
    return [true, state.upcase] if state.to_s.length == 2 && short_title_state_check?(state)
    return [true, @us_states_downcase[state.downcase]] if state.to_s.length > 2 && state_check?(state)
    [false, state]
  end

  def valid_zip_code(zip_code)
    return [false, zip_code.to_i.to_s] unless zip_code.to_i.to_s =~ /\A\d{5}\z/
    [true, zip_code.to_i.to_s]
  end

  def valid_job_service(job_name)
    # job service (Mowing, Spring Cleanup, Fertilization & can be any string)
    # valid: “Mowing”, “Gutter Cleaning”
    # invalid “Mowing!”, “Gar!”
    # “mowing!” => “Mowing”
    # “Gar!” => “Gar”

    valid_name(job_name)

  end

  def price_validation(price)
    return [false, nil] unless (price.to_s =~ /\A\d*.?\d*\z/ && price.to_i > 0)
    [true, price]
  end

  def cycle_validation(cycle)
    unless cycle.to_s =~ /\A\d*\.?\d*\z/
      cycle = cycle.gsub!(/\W|_/, "") if cycle.to_s.downcase =~ /\W|_/
      if cycle.downcase == 'weekly'
        cycle = 7
      elsif cycle.to_s.downcase == 'biweekly'
        cycle = 14
      end
    end

    return [false, nil] unless (cycle.to_s =~ /\A\d*\.?\d*\z/ && cycle.to_i > 0)
    [true, cycle.to_i]
  end

  def valid_next_job_date(job_date)

    #NEED TO DISCUSS US TIMEZONE NEED TO PARSE

    #'15/4/28' consider what 2028-04-15 dd-mm-yy
    #'15/4/2028' consider what 2028-04-15 dd-mm-yy
    #'2015/4/28' consider what 2015-04-28 yyyy-mm-dd
    #'11/10/2028' mm-dd-yyyy consider what 2028-11-10  yyyy-mm-dd
    #'2015/4/28' consider what 2015-04-28 dd-mm-yy
    #'2015/4/28' consider what 2015-04-28 dd-mm-yy


    Date.tomorrow
    Date.parse("satuday").wday
    (DateTime.current.to_date) + ((7-3)+3)
    parse_date = Chronic.parse(job_date)

    return [false, parse_date] unless parse_date.present?
    [true, parse_date]
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
      when '.csv' then
        Roo::CSV.new(file.path)
      when '.xls' then
        Roo::Excel.new(file.path, nil, :ignore)
      when '.xlsx' then
        Roo::Excelx.new(file.path, nil, :ignore)
      # when '.ods' then
      #   Roo::OpenOffice.new(file, nil, :ignore, nil)
      else
        raise "Unknown file type: #{file.original_filename}"
    end
  end

  def message_by_phone(phone_number)
    @messages = @client.account.sms.messages.list
    msg_result = {}
    if @messages.present? && phone_number.present?
      msg_result[phone_number] = []
      @messages.each do |msg|
        h = {}
        if  msg_result.has_key?(msg.from)
          h["body"] = msg.body
          h["to"] = msg.to
          h["from"] = msg.from
          h["date_sent"] = msg.date_sent
        else
          msg_result[msg.from] = []
          h["body"] = msg.body
          h["to"] = msg.to
          h["from"] = msg.from
          h["date_sent"] = msg.date_sent
        end

        msg_result[msg.from] << h
      end
    end
    msg_result
  end

  def hash_downcase_key(hash_data)
    Hash[hash_data.map { |k, v| v.class == Array ? [k, v.map { |r| f r }.to_a] : [k.downcase, v] }]
  end


  #===== Start Initialize or Processing Method ======

  #======Start Validation method ======

  def short_title_state_check?(state)
    state =~ /\A([Aa][LKSZRAEPlkszraep]|[Cc][AOTaot]|[Dd][ECec]|[Ff][LMlm]|[Gg][AUau]|[Hh][Ii]| [Ii][ADLNadln]|[Kk][SYsy]|[Ll][Aa]|[Mm][ADEHINOPSTadehinopst]|[Nn][CDEHJMVYcdehjmvy]|[Oo][HKRhkr]|[Pp][ARWarw]|[Rr][Ii]|[Ss][CDcd]|[Tt][NXnx]|[Uu][Tt]|[Vv][AITait]|[Ww][AIVYaivy])\z/
  end

  def state_check?(state)
    return true if @us_states_downcase.keys.find { |k| state.to_s.downcase == k.downcase }
    false
  end

  #=====End Validation Method ==========


  def us_states
    [
        ['Alabama', 'AL'],
        ['Alaska', 'AK'],
        ['Arizona', 'AZ'],
        ['Arkansas', 'AR'],
        ['California', 'CA'],
        ['Colorado', 'CO'],
        ['Connecticut', 'CT'],
        ['Delaware', 'DE'],
        ['District of Columbia', 'DC'],
        ['Florida', 'FL'],
        ['Georgia', 'GA'],
        ['Hawaii', 'HI'],
        ['Idaho', 'ID'],
        ['Illinois', 'IL'],
        ['Indiana', 'IN'],
        ['Iowa', 'IA'],
        ['Kansas', 'KS'],
        ['Kentucky', 'KY'],
        ['Louisiana', 'LA'],
        ['Maine', 'ME'],
        ['Maryland', 'MD'],
        ['Massachusetts', 'MA'],
        ['Michigan', 'MI'],
        ['Minnesota', 'MN'],
        ['Mississippi', 'MS'],
        ['Missouri', 'MO'],
        ['Montana', 'MT'],
        ['Nebraska', 'NE'],
        ['Nevada', 'NV'],
        ['New Hampshire', 'NH'],
        ['New Jersey', 'NJ'],
        ['New Mexico', 'NM'],
        ['New York', 'NY'],
        ['North Carolina', 'NC'],
        ['North Dakota', 'ND'],
        ['Ohio', 'OH'],
        ['Oklahoma', 'OK'],
        ['Oregon', 'OR'],
        ['Pennsylvania', 'PA'],
        ['Puerto Rico', 'PR'],
        ['Rhode Island', 'RI'],
        ['South Carolina', 'SC'],
        ['South Dakota', 'SD'],
        ['Tennessee', 'TN'],
        ['Texas', 'TX'],
        ['Utah', 'UT'],
        ['Vermont', 'VT'],
        ['Virginia', 'VA'],
        ['Washington', 'WA'],
        ['West Virginia', 'WV'],
        ['Wisconsin', 'WI'],
        ['Wyoming', 'WY']
    ]
  end

  # private
  # def assign_twilio
  #   account_sid = Rails.application.config.account_sid
  #   auth_token = Rails.application.config.auth_token
  #   @client = Twilio::REST::Client.new account_sid, auth_token
  # end


end

/**********************************************************************************
 * $URL:  $
 * $Id:  $
 ***********************************************************************************
 *
 * Copyright (c) 2007 The Sakai Foundation.
 * 
 * Licensed under the Educational Community License, Version 1.0 (the "License"); 
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at
 * 
 *      http://www.opensource.org/licenses/ecl1.php
 * 
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, 
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 * See the License for the specific language governing permissions and 
 * limitations under the License.
 *
 **********************************************************************************/
package org.sakaiproject.scorm.ui.player.pages;

import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.adl.sequencer.SeqNavRequests;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.wicket.Component;
import org.apache.wicket.PageParameters;
import org.apache.wicket.RequestCycle;
import org.apache.wicket.ajax.AjaxRequestTarget;
import org.apache.wicket.markup.html.IHeaderResponse;
import org.apache.wicket.protocol.http.WebRequest;
import org.apache.wicket.request.IRequestCodingStrategy;
import org.apache.wicket.request.target.component.BookmarkablePageRequestTarget;
import org.apache.wicket.spring.injection.annot.SpringBean;
import org.apache.wicket.util.string.AppendingStringBuffer;
import org.sakaiproject.scorm.model.api.Attempt;
import org.sakaiproject.scorm.model.api.ContentPackage;
import org.sakaiproject.scorm.model.api.SessionBean;
import org.sakaiproject.scorm.service.api.INavigable;
import org.sakaiproject.scorm.service.api.ScoBean;
import org.sakaiproject.scorm.service.api.ScormApplicationService;
import org.sakaiproject.scorm.service.api.ScormContentService;
import org.sakaiproject.scorm.service.api.ScormResultService;
import org.sakaiproject.scorm.service.api.ScormSequencingService;
import org.sakaiproject.scorm.ui.player.behaviors.ActivityAjaxEventBehavior;
import org.sakaiproject.scorm.ui.player.behaviors.CloseWindowBehavior;
import org.sakaiproject.scorm.ui.player.components.ButtonForm;
import org.sakaiproject.scorm.ui.player.components.ChoicePanel;
import org.sakaiproject.scorm.ui.player.components.DeniedPanel;
import org.sakaiproject.scorm.ui.player.components.LaunchPanel;
import org.sakaiproject.scorm.ui.player.components.LazyLoadPanel;


public class PlayerPage extends BaseToolPage implements INavigable {
	private static final long serialVersionUID = 1L;
	private static Log log = LogFactory.getLog(PlayerPage.class);
	
	@SpringBean
	ScormApplicationService api;
	@SpringBean
	ScormContentService contentService;
	@SpringBean
	ScormResultService resultService;
	@SpringBean
	ScormSequencingService sequencingService;
	
	
	private SessionBean sessionBean;

	private LaunchPanel launchPanel;
	private ActivityAjaxEventBehavior closeWindowBehavior;
	private ButtonForm buttonForm;
	
	public PlayerPage() {
		this(new PageParameters());
	}
	
	
	public PlayerPage(final PageParameters pageParams) {
		super();
		
		String courseId = pageParams.getString("courseId");
		
		sessionBean = sequencingService.newSessionBean(courseId);
		sessionBean.setCompletionUrl(getCompletionUrl());
		
		buttonForm = new ButtonForm("buttonForm", sessionBean, this);
		add(buttonForm);
				
		add(new LazyLoadPanel("actionPanel") {
			private static final long serialVersionUID = 1L;

			@Override
		    public Component getLazyLoadComponent(String lazyId, AjaxRequestTarget target) {
				return launch(sessionBean, lazyId, pageParams, target);
			}
		});
		
		//add(new AdminPanel("adminPanel", contentPackageId, runState));
		
		closeWindowBehavior = new CloseWindowBehavior(sessionBean);
		add(closeWindowBehavior);
	}
	
	
	private String getCompletionUrl() {
		RequestCycle cycle = getRequestCycle();
		IRequestCodingStrategy encoder = cycle.getProcessor().getRequestCodingStrategy();
		WebRequest webRequest = (WebRequest)getRequest();
		HttpServletRequest servletRequest = webRequest.getHttpServletRequest();
		String toolUrl = servletRequest.getContextPath();
		CharSequence completionUrl = encoder.encode(cycle, new BookmarkablePageRequestTarget(CompletionPage.class, new PageParameters()));
		AppendingStringBuffer url = new AppendingStringBuffer();
		url.append(toolUrl).append("/").append(completionUrl);
		
		return url.toString();
	}
		
	
	private Component launch(SessionBean sessionBean, String lazyId, PageParameters pageParams, AjaxRequestTarget target) {
		
		int navRequest = SeqNavRequests.NAV_START;
			
		String result = null;
		
		try {
			// FIXME: We need to make a decision here about which attempt this is. 
			// If there's already an existing, suspended attempt, then we should use that. 
			// Otherwise, set the attempt number to the next attempt 
			List<Attempt> attempts = resultService.getAttempts(sessionBean.getCourseId(), sessionBean.getLearnerId());
			
			long attemptNumber = 1;
			
			if (attempts != null && attempts.size() > 0) {
				// Since attempts are order by attempt number, descending, then the first one is the max
				Attempt attempt = attempts.get(0);
				
				if (attempt.isSuspended()) {
					// If the user suspended the last attempt, let them return to it.
					attemptNumber = attempt.getAttemptNumber();
					navRequest = SeqNavRequests.NAV_RESUMEALL;
				} else if (attempt.isNotExited()) {
					// Or if the server crashed mid-session or something, then abandon the old one and start over
					attemptNumber = attempt.getAttemptNumber();
					log.warn("Abandoning old attempt and re-starting . . . ");
					attempt.setNotExited(false);
					resultService.saveAttempt(attempt);
					sessionBean.setRestart(true);
					sequencingService.navigate(SeqNavRequests.NAV_ABANDONALL, sessionBean, this, target);
				} else {
					// Otherwise, we can start a new one
					attemptNumber = attempt.getAttemptNumber() + 1;
				}
			}
			
			sessionBean.setAttemptNumber(attemptNumber);
			
			long contentPackageId = -1;
			
			if (pageParams.containsKey("id")) {
				contentPackageId = pageParams.getLong("id");
				
				// TODO: Verify that the user is allowed to start a new attempt
				ContentPackage contentPackage = contentService.getContentPackage(contentPackageId);
				
				if (contentPackage != null && contentPackage.getNumberOfTries() != -1) {
					
					if (attemptNumber > contentPackage.getNumberOfTries())
						return new DeniedPanel(lazyId, pageParams);
				}
			}
			
			if (pageParams.containsKey("navRequest"))
				navRequest = pageParams.getInt("navRequest");
			
			result = sequencingService.navigate(navRequest, sessionBean, this, target);
			
			/*if (result != null && result.contains("_INVALIDNAVREQ_")) {
				log.warn("Abandoning old attempt and re-starting . . . ");
				sequencingService.navigate(SeqNavRequests.NAV_ABANDONALL, sessionBean, this, target);
				result = sequencingService.navigate(SeqNavRequests.NAV_START, sessionBean, this, target);
			}*/
			
			if (result == null || result.contains("_TOC_")) {
				launchPanel = new LaunchPanel(lazyId, sessionBean, PlayerPage.this);
				
				
				ScoBean scoBean = api.produceScoBean(sessionBean.getScoId(), sessionBean);
				scoBean.clearState();
				PlayerPage.this.synchronizeState(sessionBean, target);
				
				if (launchPanel.getTreePanel().getActivityTree().isEmpty()) {
					launchPanel.getTreePanel().setVisible(false);
				}
				
				displayContent(sessionBean, target);
				
				return launchPanel;
			} 
			
			log.warn("Result is " + result);
			
		} catch (Exception e) {
			result = e.getMessage();
			e.printStackTrace();
			
			log.error("Caught an exception: " , e);
		} 
		
		return new ChoicePanel(lazyId, pageParams, result);
	}
	
	public void synchronizeState(SessionBean sessionBean, AjaxRequestTarget target) {
		buttonForm.synchronizeState(sessionBean, target);
	}
	
		
	/**
	 * No need for versioning this frame.
	 * 
	 * @see org.apache.wicket.Component#isVersioned()
	 */
	public boolean isVersioned()
	{
		return false;
	}
	
	public void renderHead(IHeaderResponse response) {
		super.renderHead(response);
		
		//response.renderJavascriptReference(ORGANIZE_DIMENSIONS_JS);
		
		//response.renderOnBeforeUnloadJavascript(closeWindowBehavior.getCall());
		
		response.renderOnEventJavacript("window", "beforeunload", closeWindowBehavior.getCall());
		
		/*if (launchPanel != null) {
			StringBuffer onDomReadyJs = new StringBuffer().append(ON_DOM_READY_JS_BEGIN);
			onDomReadyJs.append(launchPanel.getMarkupId()).append(", ").append(launchPanel.getTreePanel().getMarkupId());
			onDomReadyJs.append(", ").append(" scormContent");
			onDomReadyJs.append(ON_DOM_READY_JS_END);
			
			response.renderOnDomReadyJavascript(onDomReadyJs.toString());
		}*/
	}
	
	/*public void displayContent(org.sakaiproject.scorm.client.api.IRunState runState, Object target) {
		if (null == target)
			return;
		
		if (runState.isEnded()) {
			//completionUrl = completionUrl + "&KeepThis=true&TB_iframe=true&height=400&width=600&modal=true";
						
			((AjaxRequestTarget)target).appendJavascript("window.location.href='" + runState.getCompletionUrl() + "';");
		}
		
		String url = runState.getCurrentHref();
		if (null != url) {
			if (log.isDebugEnabled())
				log.debug("Going to " + url);
			
			((AjaxRequestTarget)target).appendJavascript("parent.scormContent.location.href='" + url + "'");
		} else {
			log.warn("Url is null!");
		}
	}*/
	
	public void displayContent(SessionBean sessionBean, Object target) {
		if (null == target)
			return;
		
		if (sessionBean.isEnded()) {		
			((AjaxRequestTarget)target).appendJavascript("window.location.href='" + sessionBean.getCompletionUrl() + "';");
		}
		
		String url = sequencingService.getCurrentUrl(sessionBean);
		if (null != url) {
			if (log.isDebugEnabled())
				log.debug("Going to " + url);
			
			((AjaxRequestTarget)target).appendJavascript("parent.scormContent.location.href='" + url + "'");
		} else {
			log.warn("Url is null!");
		}
	}
	
	

	public ButtonForm getButtonForm() {
		return buttonForm;
	}
	
	public LaunchPanel getLaunchPanel() {
		return launchPanel;
	}

	
}
